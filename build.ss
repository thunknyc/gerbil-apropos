#!/usr/bin/env gxi

(import :std/build-script)

(defbuild-script
  '("apropos"
    ;;     v--source?          v--binary?
    (exe: "apropos-tool" bin: "gxapropos")))
