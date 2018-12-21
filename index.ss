;;
;; Gerbil module index generator
;; Edwin Watkeys, edw@poseur.com
;;
;; Usage example: (def e (all-exports))
;;
;; ALL-EXPORTS finds every .ssi file in EXPANDER-LOAD-PATH and attempts to
;; determine every time of every exported name. An attempt is made to import
;; every module, as determining what a non-syntax export is requires evaluating
;; it.
;;
;; Exports are collected in a return hash-table. Each key represents a name.
;; The value of each key is a list of each module in which that name is found
;; along with an inferred type, currently syntax, procedure, value, or
;; unknown. A name's type is unknown if it cannot be evaluated.
;;

(import <expander-runtime>
        :std/format
        :std/iter
        :std/sort
        :std/sugar
        (only-in :std/srfi/13 string-suffix? string-drop string-drop-right find)
        (only-in :std/srfi/1 append-map concatenate fold))

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

(def (binding-type b)
  (try
   (cond ((syntax-binding? b) 'syntax)
         ((eval (binding-id b))
          => (lambda (o)
               (cond ((procedure? o) 'procedure)
                     (else 'value)))))
   (catch (e)
     ;; (eprintf "Error evaluating ~S\n"
     ;;          (binding-id b))
     'unknown)))

(def (merge-export entry mod type)
  (let (entry (cons (list mod type) entry))
    (sort entry (lambda (a b)
                  (string<? (symbol->string (car a))
                            (symbol->string (car b)))))))

(def (export-add! exports name mod type)
  (let* ((name-entry (hash-ref exports name '())))
    (hash-put! exports name (merge-export name-entry mod type))))

(def (accumulate-exports! mod+file accum)
  (with ([mod file] mod+file)
    (let* ((ctx (import-module file))
           (exports (module-context-export ctx)))
      (for (x (reverse exports))
        (let* ((name (module-export-name x))
               (binding (core-resolve-module-export x))
               (type (binding-type binding)))
          (export-add! accum name mod type)))
      accum)))

(def (import-modules mods)
  (for-each (lambda (mod+file)
              (with ([mod file] mod+file)
                (try
                 (load-module (string-append (string-drop-right file 4)
                                             "__rt"))
                 (catch (e) (eprintf "Error loading: ~S\n file: ~S\n"
                                     mod file)))))
            mods))

(def (all-exports)
  (let (mods (module-forest))
    (import-modules mods)
    (fold accumulate-exports! (make-hash-table-eq) mods)))
