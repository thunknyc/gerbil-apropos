# Gerbil apropos
For generating exported Gerbil names.

## Installation

```
gxpkg install github.com/thunknyc/gerbil-apropos
```

## Usage

`(import :thunknyc/apropos)`

> Import the apropos library.

`apropos-re re-str [apropos-db]` 
`apropos string-or-symbol [apropos-db]`

> Core lookup procedures. Use them to produce a list of matching
names and modules using either a regular expression string
(`apropos-re`) or a string or symbol (`apropos`) to match.

`make-apropos-db [load-path]`

> Construct a new apropos database object and return it.

`current-apropos-db [new-db]`
> If evaluated with no arguments, return the current apropo database
object. If evaluated with one argument, set the current apropos
database to `new-db`.

`module-exports module-name-symbol`
> Determine all exports of a module, given as a symbol
e.g. `':thunknyc/apropos`.
