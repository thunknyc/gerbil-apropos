;;
;; Gerbil module index generator
;; Edwin Watkeys, edw@poseur.com
;;
;; Usage example: (def e (all-exports))
;;

(import <expander-runtime>
        :gerbil/expander
        :std/format
        :std/iter
        :std/sort
        :std/sugar
        :std/srfi/13
        (only-in :std/srfi/1 append-map concatenate delete-duplicates! fold))

(def (file-directory? f)
  (eq? (file-type f) 'directory))

(def (ssi-file? f)
  (string-suffix? ".ssi" f))

(def (ssi-file->module-name f base)
  (let (base (if (string-suffix? "/" base) base (string-append base "/")))
    (string-drop-right (string-drop f (string-length base))
                       (string-length ".ssi"))))

(def (module-tree d base)
  (let* ((tree (map (lambda (f) (path-expand f d)) (directory-files d)))
         (children (map (lambda (d) (module-tree d base))
                        (filter file-directory? tree)))
         (module-file-names (filter ssi-file? tree)))
    (append module-file-names (concatenate children))))

(def (module-forest)
  (append-map (lambda (d) (module-tree d d)) (expander-load-path)))

(def (eval-in-context name ctx)
  (parameterize ((current-expander-context ctx))
    (eval name)))

(def (object-type-name o)
  (caddr (struct->list (object-type o))))

(def (binding-type b ctx)
  (try
    (let (o (eval-in-context (binding-id b) ctx))
      (cond ((procedure? o) 'procedure)
            ((object? o) (object-type-name o))
            (else 'unknown)))
    (catch (e) 'syntax)))

(def (module-binding-type b ctx (quiet? #f))
  (cond ((module-binding? b) (binding-type b ctx))
        ((syntax-binding? b) 'syntax)
        ((extern-binding? b)
         (binding-type
          (resolve-identifier (binding-id b) (current-expander-phi) ctx)
          ctx))
        ((top-binding? b) 'top)
        ((alias-binding? b)
         (module-binding-type (resolve-identifier (alias-binding-e b)) ctx))
        ((import-binding? b)
         (if quiet?
           (module-binding-type (import-binding-e b) ctx #t)
           `(imported ,(module-binding-type (import-binding-e b) ctx #t))))
        (else
         `(other ,b))))

(def (module-context-exports ctx)
  (let* ((mod-name (expander-context-id ctx))
         (exports (module-context-export ctx)))
    (map (lambda (e)
           (let* ((name (module-export-name e))
                  (binding (core-resolve-module-export e))
                  (type (module-binding-type binding ctx)))
             (list mod-name name type)))
         (reverse exports))))

(def (module-exports mod)
  (let (ctx (import-module mod #t #t))
    (module-context-exports ctx)))

(def (merge-export entry mod type)
  (cons (list mod type) entry))

(def (export-add! exports-hash index name mod type)
  (let* ((index-hash (hash-ref exports-hash index (make-hash-table)))
         (name-list (hash-ref index-hash name '()))
         (new-name-list (merge-export name-list mod type)))
    (hash-put! index-hash name new-name-list)
    (hash-put! exports-hash index index-hash)))

(def (accumulate-exports! file accum)
  (let (ctx (import-module file #t #t))
    (for (e (module-context-exports ctx))
      (with ([mod name type] e)
        (export-add! accum 'names name mod type)
        (export-add! accum 'modules mod name type)))
    accum))

(def (tidy-entry col)
  (delete-duplicates!
   (sort! col (lambda (a b)
                (string<? (symbol->string (car a))
                          (symbol->string (car b)))))))

(def (tidy-index! e index)
  (let (index-hash (hash-ref e index (make-hash-table-eq)))
    (hash-for-each (lambda (k v) (hash-put! index-hash k (tidy-entry v)))
                   index-hash))
  e)

(def (tidy-exports! e)
  (tidy-index! e 'names)
  (tidy-index! e 'modules)
  e)

(def (all-exports)
  (let (mods (module-forest))
    (tidy-exports! (fold accumulate-exports! (make-hash-table-eq) mods))))

(def names-indices (all-exports))

(def (hash-ref-in h ks (default '()))
  (let lp ((ks ks) (h h))
    (if (null? ks) h
        (lp (cdr ks) (hash-ref h (car ks) default)))))

(def (matching-keys h thing)
  (filter (lambda (k)
            (string-contains (symbol->string k) thing))
          (hash-keys h)))

(def (export-apropos* what q)
  (matching-keys (hash-ref names-indices what) q))

(def (apropos-results what ks)
  (list what
        (map
         (lambda (k) (list k (hash-ref-in names-indices (list what k))))
         ks)))

(def (exports-apropos thing)
  (let* ((q (format "~A" thing))
         (names (export-apropos* 'names q))
         (modules (export-apropos* 'modules q)))
    (map (cut apropos-results <> <>) '(names modules) (list names modules))))
