;;; kbd-mode.el --- Font locking for kmonad's .kbd files -*- lexical-binding: t -*-

;; Copyright 2020  slotThe
;; URL: https://github.com/slotThe/kbd-mode
;; Version: 0.0.1

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This file adds basic font locking support for `.kbd' configuration
;; files.

;; To use this file, move it to a directory within your `load-path' and
;; require it.  For example --- assuming that this file was placed
;; within the `~/.config/emacs/elisp' directory:
;;
;;     (add-to-list 'load-path "~/.config/emacs/elisp/")
;;     (require 'kbd-mode)
;;
;; If you use `use-package', you can express the above as
;;
;;     (use-package kbd-mode
;;       :load-path "~/.config/emacs/elisp/")

;; By default we highlight all keywords; you can change this by
;; customizing the `kbd-mode-' variables.  For example, to disable the
;; highlighting of already defined macros (i.e. of "@macro-name"), you
;; can set `kbd-mode-show-macros' to `nil'.

;;; Code:

(defgroup kbd nil
  "Major mode for editing `.kbd' files."
  :group 'languages)

;;; Custom variables

(defgroup kbd-highlight nil
  "Syntax highlighting for `kbd-mode'."
  :group 'kbd)

(defcustom kbd-mode-kexpr
  '("defcfg" "defsrc" "defalias")
  "A K-Expression."
  :type '(repeat string)
  :group 'kbd-highlight)

;; HACK
(defcustom kbd-mode-function-one
  '("deflayer")
  "Tokens that are treated as functions with one argument."
  :type '(repeat string)
  :group 'kbd-highlight)

(defcustom kbd-mode-tokens
  '(;; input tokens
    "uinput-sink" "send-event-sink" "kext"
    ;; output tokens
    "device-file" "low-level-hook" "iokit-name")
  "Input and output tokens."
  :type '(repeat string)
  :group 'kbd-highlight)

(defcustom kbd-mode-defcfg-options
  '("input" "output" "cmp-seq" "init" "fallthrough" "allow-cmd")
  "Options to give to `defcfg'."
  :type '(repeat string)
  :group 'kbd-highlight)

(defcustom kbd-mode-button-modifiers
  '("around" "multi-tap" "tap-hold" "tap-hold-next" "tap-next-release"
    "tap-hold-next-release" "tap-next" "layer-toggle" "layer-switch"
    "layer-add" "layer-rem" "layer-delay" "layer-next" "around-next"
    "tap-macro" "cmd-button")
  "Button modifiers."
  :type '(repeat string)
  :group 'kbd-highlight)

(defcustom kbd-mode-show-string
  '("uinput-sink" "device-file" "cmd-button")
  "Syntax highlight strings in S-expressions.
When an S-expression begins with any of these keywords, highlight
strings (delimited by double quotes) inside it."
  :type '(repeat string)
  :group 'kbd-highlight)

(defcustom kbd-mode-show-macros t
  "Whether to syntax highlight macros inside layout definitions.
Default: t"
  :type 'boolean
  :group 'kbd-highlight)

;;; Faces

(defgroup kbd-highlight-faces nil
  "Faces used for highlighting in `kbd-mode'."
  :group 'kbd-highlight)

(defface kbd-mode-kexpr-face
  '((t :inherit font-lock-keyword-face))
  "Face for a K-Expression"
  :group 'kbd-highlight-faces)

(defface kbd-mode-token-face
  '((t :inherit font-lock-function-name-face))
  "Face for input and output tokens"
  :group 'kbd-highlight-faces)

(defface kbd-mode-defcfg-option-face
  '((t :inherit font-lock-builtin-face))
  "Face for options one may give to `defcfg'"
  :group 'kbd-highlight-faces)

(defface kbd-mode-button-modifier-face
  '((t :inherit font-lock-function-name-face))
  "Face for all the button modifiers"
  :group 'kbd-highlight-faces)

(defface kbd-mode-variable-name-face
  '((t :inherit font-lock-variable-name-face))
  "Face for a variables, i.e. layer names, macros in layers,..."
  :group 'kbd-highlight-faces)

(defface kbd-mode-string-face
  '((t :inherit font-lock-string-face))
  "Face for strings"
  :group 'kbd-highlight-faces)

;;; Functions

(defun kbd-mode--show-macros? (show-macros)
  "Decide whether to highlight macros.
If SHOW-MACROS is nil, don't highlight macros of the form
`@MACRO-NAME' (e.g. in a `deflayer' expression)."
  (let ((macro-regexp '(("\\(:?\\(@[^[:space:]]+\\)\\)"
                         (1 'kbd-mode-variable-name-face)))))
    (if show-macros
        (font-lock-add-keywords 'kbd-mode macro-regexp)
      (font-lock-remove-keywords 'kbd-mode macro-regexp))))

;;; Vars

(defvar kbd-mode-syntax-table
  (let ((st (make-syntax-table)))
    ;; Use ;; for regular comments and #| |# for line comments.
    (modify-syntax-entry ?\; ". 12b" st)
    (modify-syntax-entry ?\n "> b"   st)
    (modify-syntax-entry ?\# ". 14"  st)
    (modify-syntax-entry ?\| ". 23"  st)

    ;; We don't need to highlight brackets, as they're only used inside
    ;; layouts.
    (modify-syntax-entry ?\[ "."     st)
    (modify-syntax-entry ?\] "."     st)

    ;; We highlight the necessary strings ourselves.
    (modify-syntax-entry ?\" "."     st)
    st)
  "The basic syntax table for `kbd-mode'.")


(defvar kbd-mode--font-lock-keywords
  '(((kexpr-regexp            (regexp-opt kbd-mode-kexpr            'words))
       (token-regexp            (regexp-opt kbd-mode-tokens           'words))
       (defcfg-options-regexp   (regexp-opt kbd-mode-defcfg-options   'words))
       (button-modifiers-regexp (regexp-opt kbd-mode-button-modifiers 'words))
       (function-one-regexp
        (concat "\\(?:\\("
                (regexp-opt kbd-mode-function-one)
                "\\)\\([[:space:]]+[[:word:]]+\\)\\)"))
       ;; Only highlight these strings; configuration files may
       ;; explicitly use a " to emit a double quote, so we can't trust
       ;; the default string highlighting.
       (string-regexp
        (concat "\\(['\(]"
                (regexp-opt kbd-mode-show-string)
                "\\)\\(\\S)+\\)\)")))

   `((,token-regexp            (1 'kbd-mode-token-face          ))
     (,kexpr-regexp            (1 'kbd-mode-kexpr-face          ))
     (,button-modifiers-regexp (1 'kbd-mode-button-modifier-face))
     (,defcfg-options-regexp   (1 'kbd-mode-defcfg-option-face  ))
     (,function-one-regexp
      (1 'kbd-mode-kexpr-face        )
      (2 'kbd-mode-variable-name-face))
     (,string-regexp
      ("\"[^}]*?\""
       (progn (goto-char (match-beginning 0)) (match-end 0))
       (goto-char (match-end 0))
       (0 'kbd-mode-string-face t)))))
    "Keywords to be syntax highlighted.")

;;; Define Major Mode

;; Because the configuration language is a tiny subset of LISP, we can
;; inherit from any LISP mode in order to get good parenthesis handling
;; for free.

;;;###autoload
(define-derived-mode kbd-mode emacs-lisp-mode "Kbd"
  "Major mode for editing `.kbd' files.

For details, see `https://github.com/david-janssen/kmonad'."

  (set-syntax-table kbd-mode-syntax-table)
  (font-lock-add-keywords 'kbd-mode kbd-mode--font-lock-keywords)
  (kbd-mode--show-macros? kbd-mode-show-macros)

  ;; HACK
  (defadvice redisplay (after refresh-font-locking activate)
    (when (derived-mode-p 'kbd-mode)
      (font-lock-fontify-buffer))))

;; Associate the `.kbd' ending with `kbd-mode'.
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.kbd\\'" . kbd-mode))

(provide 'kbd-mode)

;;; kbd-mode.el ends here
