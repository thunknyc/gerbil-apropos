#!/usr/bin/env gxi

(import :std/build-script)

(defbuild-script
  '("apropos"
    (exe: "apropos-tool" bin: "gxapropos")))
