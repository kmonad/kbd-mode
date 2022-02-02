# kbd-mode

An Emacs mode for syntax highlighting [kmonad's] `.kbd` files.  Because
the configuration language has a lisp-ish syntax, you will find this
very close to a regular lisp editing experience.

# Installation

## Manually

Copy `kbd-mode.el` into a directory within your `load-path` and require
it.  For example---assuming that this file was placed within the
`~/.config/emacs/elisp` directory:

``` emacs-lisp
(add-to-list 'load-path "~/.config/emacs/elisp/")
(require 'kbd-mode)
```

If you use [use-package], you can express the above as

``` emacs-lisp
(use-package kbd-mode
  :load-path "~/.config/emacs/elisp/")
```

If you use [Spacemacs], add the following in the
`dotspacemacs-additional-packages` section:

``` emacs-lisp
(kbd-mode
 :location
 (recipe
  :fetcher github
  :repo "kmonad/kbd-mode"))
```

If you use [Doom Emacs], add the followings in the
`packages.el` and `config.el` respectively.

``` emacs-lisp
(package! kbd-mode
  :recipe (:host github
           :repo "kmonad/kbd-mode"))
```

``` emacs-lisp
(use-package! kbd-mode)
```

## GNU Guix

On Guix, kbd-mode can be installed via `guix install`:

``` console
$ guix install emacs-kbd
```

[kmonad's]: https://github.com/david-janssen/kmonad
[Spacemacs]: https://develop.spacemacs.org
[use-package]: https://github.com/jwiegley/use-package
[Doom Emacs]: https://github.com/hlissner/doom-emacs
