# kbd-mode

An Emacs major-mode for syntax highlighting [kmonad]'s `.kbd` files.
Because the configuration language has a lisp-ish syntax, you will find
this very close to a regular lisp editing experience.

We provide the following additional keybindings
(see [Demo Mode](#demo-mode) for more information):

| Keybinding | Function              |
|------------|-----------------------|
| `C-c C-c`  | `kbd-mode-start-demo` |
| `C-c C-z`  | `kbd-mode-switch`     |

# Installation

## Manually

Copy `kbd-mode.el` into a directory within your `load-path` and require
it.  For example, assuming that this file was placed within the
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

## Quelpa

If you use [quelpa] and [quelpa-use-package], you can install directly
from its repository:

``` emacs-lisp
(use-package kbd-mode
  :quelpa (kbd-mode :fetcher github :repo "kmonad/kbd-mode")
  :mode "\\.kbd\\'"
  :commands kbd-mode)
```

## Spacemacs

If you use [Spacemacs], add the following in the
`dotspacemacs-additional-packages` section:

``` emacs-lisp
(kbd-mode
 :location
 (recipe
  :fetcher github
  :repo "kmonad/kbd-mode"))
```

## Doom Emacs

If you use [Doom Emacs], add the followings in the `packages.el` and
`config.el` respectively.

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

[Doom Emacs]: https://github.com/hlissner/doom-emacs
[Spacemacs]: https://develop.spacemacs.org
[kmonad]: https://github.com/kmonad/kmonad
[quelpa-use-package]: https://github.com/quelpa/quelpa-use-package
[quelpa]: https://github.com/quelpa/quelpa
[use-package]: https://github.com/jwiegley/use-package

# Demo Mode

The minor mode `kbd-mode-demo-mode` allows you to try out your
configuration in a separate buffer.

Usage of this mode requires you to first customize the
`kbd-mode-kill-kmonad` and `kbd-mode-start-kmonad` variables.  If
applicable, these are used for killing and (re-)starting your regular
kmonad process.

For example:

``` emacs-lisp
(use-package kbd-mode
  :load-path "~/.config/emacs/elisp/"
  :custom
  (kbd-mode-kill-kmonad "pkill -9 kmonad")
  (kbd-mode-start-kmonad "kmonad ~/path/to/config.kbd"))
```

Note that, in general, it is not a good idea to run kmonad with root
privileges.  As such, `kbd-mode-demo-mode` only handles your
configuration correctly if it was started as a regular user.

## Starting and Stopping the Demo

To start the demo, either run `M-x kbd-mode-start-demo RET` or the
corresponding keybinding, `C-c C-c`, for it.  If current files extension
is `.kbd` it's automatically selected as chosen configuration file.
Else you'll be prompted for a file.

If your configuration does not compile, the current (working) kmonad
process will not be killed and the demo won't start.  Instead, an error
buffer will be shown.

By default, start a demo process upon entering `kbd-mode-demo-mode` and
stop it (starting an appropriate "normal" kmonad instance if needed)
when exiting the mode with `C-c C-c` (`kbd-mode-stop-demo`).

If you set the variable `kbd-mode-magic-focus` to `t`, then this process
will also happen whenever focus changes with regards to the
`*kmonad-demo*` buffer.  I.e., whenever you change focus from the demo
buffer to another buffer, the demo process will be killed and a normal
process starts.  Likewise, when you switch _to_ the demo buffer, your
existing kmonad instance (if any) will be killed and a new demo.
