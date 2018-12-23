(export main)

(import :std/iter
        :std/format
        :thunknyc/apropos)

(def (main . args)
  ;(init-apropos)
  (for ((a args))
    (printf "~S\n" (apropos-re a))))