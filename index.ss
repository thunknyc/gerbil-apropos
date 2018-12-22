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
        (only-in :std/generic type-of)
        (only-in :std/srfi/1 append-map concatenate delete-duplicates fold))

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
         (ssi-files (filter ssi-file? tree))
         (module-names (map (lambda (m) (ssi-file->module-name m base))
                            ssi-files))
         (module-file-names ssi-files))
    (append (map (lambda (n f) (list (string->symbol n) f))
                 module-names module-file-names)
            (concatenate children))))

(def (module-forest)
  (append-map (lambda (d) (module-tree d d)) (expander-load-path)))

(def (eval-in-context name ctx)
  (parameterize ((current-expander-context ctx))
    (eval name)))

(def (bound-in-context? name ctx)
  (parameterize ((current-expander-context ctx))
    (core-bound-identifier? name)))

(def (object-type-name o)
  (caddr (struct->list (object-type o))))

(def (binding-type b ctx)
  (if (bound-in-context? b ctx)
    (let (o (eval-in-context (binding-id b) ctx))
      (cond ((procedure? o) 'procedure)
            ((object? o) (object-type-name o))
            (else 'unknown)))
    'syntax))

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
  (let (entry (cons (list mod type) entry))
    (delete-duplicates
     (sort! entry (lambda (a b)
                    (string<? (symbol->string (car a))
                              (symbol->string (car b)))))
     equal?)))

(def (export-add! exports name mod type)
  (let* ((name-entry (hash-ref exports name '())))
    (hash-put! exports name (merge-export name-entry mod type))))

(def (accumulate-exports! mod+file accum)
  (with ([mod file] mod+file)
    (let* (ctx (import-module file #t #t))
      (for (e (module-context-exports ctx))
        (with ([mod name type] e)
          (export-add! accum name mod type)))
      accum)))

(def (all-exports)
  (let (mods (module-forest))
    (fold accumulate-exports! (make-hash-table-eq) mods)))
