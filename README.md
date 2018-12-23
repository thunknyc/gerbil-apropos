# Gerbil apropos
For generating exported Gerbil names.

## Installation

```
gxpkg install github.com/thunknyc/gerbil-apropos
```

## Usage

`$ gxapropos [re-string] ...`

> The `gxapropos` tool, installed in `~/.gerbil/bin`, will evaluate
  `apropos-re`, described below, on each command line argument.

`gxaproposd` (Not currently implemented)

> The `gxaproposd` daemon will output results for each regular
  expression sent to stdin followed by a newline. This allows the small
  but non-trivial startup time associated with constructing the
  apropos database to be amortized over potentially many lookups.

`(import :thunknyc/apropos)`

> Import the apropos library.

### Procedures

`init-apropos`

> If you use this module from a compiled program, you must evaluate
  this procedure before evaluating any of the procedures below. It
  properly initializes the runtime expander, which is not typically
  available in compiled programs.

`apropos-re re-str [apropos-db]`  
`apropos string-or-symbol [apropos-db]`

> Core lookup procedures. Produce a list of matching names and modules
  using either a regular expression string (`apropos-re`) or a string
  or symbol (`apropos`) to match on a substring basis.

`make-apropos-db [load-path]`

> Construct a new apropos database object and return it.

`current-apropos-db [new-db]`

> If evaluated with no arguments, return the current apropo database
  object. If evaluated with one argument, set the current apropos
  database to `new-db`.

`module-exports module-name-symbol`

> Determine all exports of a module, given as a symbol
  e.g. `':thunknyc/apropos`.
