# kbd-mode

An Emacs mode for syntax highlighting
[kmonad's](https://github.com/david-janssen/kmonad) `.kbd` files.
Because the configuration language is very close to a LISP, inheriting
from any of Emacs' many LISP modes will also give us sensible
parenthesis handling for free!

# Installation

## Manually
Copy `kbd-mode.el` into a directory within your `load-path` and require
it.  For example---assuming that this file was placed within the
`~/.config/emacs/elisp` directory:

``` emacs-lisp
(add-to-list 'load-path "~/.config/emacs/elisp/")
(require 'kbd-mode)
```

If you use `use-package`, you can express the above as

``` emacs-lisp
(use-package kbd-mode
  :load-path "~/.config/emacs/elisp/")
```

## GNU Guix
```guix install emacs-kbd```
