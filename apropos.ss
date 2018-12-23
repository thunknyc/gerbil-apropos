;;
;; Gerbil apropos facility
;; Edwin Watkeys, edw@poseur.com
;;

(import :gerbil/expander
        :std/format
        :std/iter
        :std/sort
        :std/sugar
        :std/srfi/13
        :std/pregexp
        (only-in :std/srfi/1 append-map concatenate delete-duplicates! fold))

(export current-apropos-db
        make-apropos-db
        apropos apropos-re
        module-exports)

(extern namespace: #f expander-load-path)

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

(def (module-forest load-path)
  (append-map (lambda (d) (module-tree d d)) load-path))

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

(def apropos-keys '(names modules))

(def (tidy-entry entry)
  (delete-duplicates!
   (sort! entry (lambda (a b)
                (string<? (symbol->string (car a))
                          (symbol->string (car b)))))))

(def (tidy-index! adb index)
  (let (index-hash (hash-ref adb index (make-hash-table-eq)))
    (hash-for-each (lambda (k v)
                     (hash-put! index-hash k (tidy-entry v)))
                   index-hash))
  adb)

(def (tidy-exports! adb)
  (for-each (lambda (n) (tidy-index! adb n)) apropos-keys)
  adb)

(def (make-apropos-db (load-path (expander-load-path)))
  (let (mods (module-forest load-path))
    (tidy-exports! (fold accumulate-exports! (make-hash-table-eq) mods))))

(def private-current-apropos-db (make-apropos-db))

(def (current-apropos-db . o)
  (if (pair? o)
    (let (new (car o)) (set! private-current-apropos-db new))
    private-current-apropos-db))

(def (hash-ref-in h ks (default '()))
  (let lp ((ks ks) (h h))
    (if (null? ks) h
        (lp (cdr ks) (hash-ref h (car ks) default)))))

(def (matching-keys h proc)
  (filter proc (hash-keys h)))

(def (apropos-index adb what filter-proc)
  (matching-keys (hash-ref adb what) filter-proc))

(def (apropos-results adb what filter-proc)
  (let (ks (apropos-index adb what filter-proc))
    (list what
          (map (lambda (k)
                 (list k (hash-ref-in adb (list what k))))
               ks))))

(def (re-filter-proc q)
  (lambda (sym) (pregexp-match q (symbol->string sym))))

(def (contains-filter-proc q)
  (lambda (sym) (string-contains (symbol->string sym) q)))

(def (apropos-re re-str (adb private-current-apropos-db))
  (let* ((q (pregexp re-str))
         (filter-proc (re-filter-proc q)))
    (map (cut apropos-results adb <> filter-proc) apropos-keys)))

(def (apropos thing (adb private-current-apropos-db))
  (let* ((q (format "~A" thing))
         (filter-proc (contains-filter-proc q)))
    (map (cut apropos-results adb <> filter-proc) apropos-keys)))
