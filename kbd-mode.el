;;; kbd-mode.el --- Font locking for kmonad's .kbd files -*- lexical-binding: t -*-

;; Copyright 2020–2022  slotThe
;; URL: https://github.com/kmonad/kbd-mode
;; Version: 0.0.1
;; Package-Requires: ((emacs "24.3"))

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This file adds basic font locking support for `.kbd' configuration
;; files.
;;
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
;;
;; By default we highlight all keywords; you can change this by
;; customizing the `kbd-mode-' variables.  For example, to disable the
;; highlighting of already defined macros (i.e. of "@macro-name"), you
;; can set `kbd-mode-show-macros' to `nil'.
;;
;; For keybindings, as well as commentary on the `kbd-mode-demo-mode'
;; minor mode, see the associated README.md file.

;;; Code:

(require 'compile)

(defgroup kbd nil
  "Major mode for editing `.kbd' files."
  :group 'languages)

(defgroup kbd-demo nil
  "A minor mode to test your configuration."
  :group 'kbd)

;;;; Custom variables

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
  '("input" "output" "cmp-seq-delay" "cmp-seq" "init" "fallthrough" "allow-cmd")
  "Options to give to `defcfg'."
  :type '(repeat string)
  :group 'kbd-highlight)

(defcustom kbd-mode-button-modifiers
  '("around-next-timeout" "around-next-single" "around-next" "around"
    "tap-hold-next-release" "tap-hold-next" "tap-next-release" "tap-hold"
    "tap-macro-release" "tap-macro" "multi-tap" "tap-next" "layer-toggle"
    "layer-switch" "layer-add" "layer-rem" "layer-delay" "layer-next" "cmd-button")
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

(defcustom kbd-mode-magic-focus nil
  "Whether to enable magic focus.
Whenever the `kbd-mode-demo-mode' buffer gets focused,
automatically start try to start a new process for the config
file.  When switching back to the config file, kill that process.

Default: nil"
  :type 'boolean
  :group 'kbd-demo)

(defcustom kbd-mode-kill-kmonad nil
  "How to kill (or suspend) a running kmonad instance.
This is used when invoking `kbd-mode-start-demo' and, in general,
when entering `kbd-mode-demo-mode' because keyboards can't be
grabbed twice."
  :type 'string
  :group 'kbd-demo)

(defcustom kbd-mode-start-kmonad nil
  "How to restart (or resume) kmonad.
If there was an active kmonad instance running, which was killed
by `kbd-mode-kill-kmonad', then this (re)starts kmonad with the
given command upon exiting `kbd-mode-demo-mode'."
  :type 'string
  :group 'kbd-demo)

;;;; Faces

(defgroup kbd-highlight-faces nil
  "Faces used for highlighting in `kbd-mode'."
  :group 'kbd-highlight)

(defface kbd-mode-kexpr-face
  '((t :inherit font-lock-keyword-face))
  "Face for a K-Expression."
  :group 'kbd-highlight-faces)

(defface kbd-mode-token-face
  '((t :inherit font-lock-function-name-face))
  "Face for input and output tokens."
  :group 'kbd-highlight-faces)

(defface kbd-mode-defcfg-option-face
  '((t :inherit font-lock-builtin-face))
  "Face for options one may give to `defcfg'."
  :group 'kbd-highlight-faces)

(defface kbd-mode-button-modifier-face
  '((t :inherit font-lock-function-name-face))
  "Face for all the button modifiers."
  :group 'kbd-highlight-faces)

(defface kbd-mode-variable-name-face
  '((t :inherit font-lock-variable-name-face))
  "Face for a variables, i.e. layer names, macros in layers,..."
  :group 'kbd-highlight-faces)

(defface kbd-mode-string-face
  '((t :inherit font-lock-string-face))
  "Face for strings."
  :group 'kbd-highlight-faces)

;;;; Functions

(defun kbd-mode--show-macros? (show-macros)
  "Decide whether to font-lock macros.
If the argument SHOW-MACROS is non-nil, font-lock macros of the
form `@MACRO-NAME' with `kbd-mode-variable-name-face'."
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
  (let ((kexpr-regexp            (regexp-opt kbd-mode-kexpr            'words))
        (token-regexp            (regexp-opt kbd-mode-tokens           'words))
        (defcfg-options-regexp   (regexp-opt kbd-mode-defcfg-options   'words))
        (button-modifiers-regexp (regexp-opt kbd-mode-button-modifiers 'words))
        (function-one-regexp
         (concat "\\(?:\\("
                 (regexp-opt kbd-mode-function-one)
                 "\\)\\([[:space:]]+[[:word:]]+\\)\\)"))
        ;; Only highlight these strings; configuration files may explicitly
        ;; use a " to emit a double quote, so we can't trust the default
        ;; string highlighting.
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

;; Because the configuration language is in a lispy syntax, we can
;; inherit from any lisp mode in order to get good parenthesis handling
;; for free.

(defvar kbd-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-c") #'kbd-mode-start-demo)
    (define-key map (kbd "C-c C-z") #'kbd-mode-switch)
    map))

;;;###autoload
(define-derived-mode kbd-mode emacs-lisp-mode "Kbd"
  "Major mode for editing `.kbd' files.

For details, see `https://github.com/kmonad/kmonad'."
  (set-syntax-table kbd-mode-syntax-table)
  (use-local-map kbd-mode-map)
  (font-lock-add-keywords 'kbd-mode kbd-mode--font-lock-keywords)
  (kbd-mode--show-macros? kbd-mode-show-macros)
  ;; HACK
  (defadvice redisplay (after refresh-font-locking activate)
    (when (derived-mode-p 'kbd-mode)
      (font-lock-fontify-buffer))))

;; Associate the `.kbd' ending with `kbd-mode'.
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.kbd\\'" . kbd-mode))

;;;; Demo Minor Mode

(defvar kbd-mode-demo-file nil
  "Path to the users configuration file.
This is used in `kbd-mode-demo-mode' for deciding what
configuration to compile.")

(defvar kbd-mode-had-kmonad? nil
  "Whether the user had a running kmonad instance.
This controls whether kmonad will be restarted by mean of
`kbd-mode-start-kmonad' after exiting `kbd-mode-demo-mode'.")

(defvar kbd-mode-demo-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-c") #'kbd-mode-stop-demo)
    (define-key map (kbd "C-c C-z") #'kbd-mode-switch)
    map))

;;;###autoload
(define-minor-mode kbd-mode-demo-mode
  "Toggle kmonad demo mode.
This is a minor mode, in which users can test their
configurations."
  :lighter " kbd-demo"
  :keymap kbd-mode-demo-mode-map

  (when kbd-mode-demo-mode
    (unless (kbd-mode--valid-config?)
      (kbd-mode--show-error)))

  ;; Handle toggle
  (when kbd-mode-magic-focus
    (cond (kbd-mode-demo-mode
           (add-hook 'window-selection-change-functions #'kbd-mode--toggle-demo nil t)
           (add-hook 'focus-in-hook #'kbd-mode--create-kmonad-process nil t)
           (add-hook 'focus-out-hook #'kbd-mode--kill-demo-process nil t))
          (t
           (remove-hook 'window-selection-change-functions #'kbd-mode--toggle-demo t)
           (remove-hook 'focus-in-hook #'kbd-mode--create-kmonad-process t)
           (remove-hook 'focus-out-hook #'kbd-mode--kill-demo-process t)))))

;;;; Interactive Functions

;;;###autoload
(defun kbd-mode-start-demo ()
  "Try the current configuration in a demo buffer.
Use `kbd-mode-stop-demo' to stop the demo.  If the configuration
file has errors, the demo will not start and an error buffer will
be shown instead."
  (interactive)
  (setq kbd-mode-demo-file
        (kbd-mode--find-kbd-file (buffer-file-name (current-buffer))))
  (if (not (kbd-mode--valid-config?))
      (kbd-mode--show-error)
    (when (shell-command "ps -C kmonad")
      (setq kbd-mode-had-kmonad? t)
      (kbd-mode--kill-kmonad))
    (kbd-mode--create-demo-buffer)
    (pop-to-buffer "*kmonad-demo*")
    (kbd-mode--create-kmonad-process)
    (kbd-mode-demo-mode t)))

(defun kbd-mode-stop-demo ()
  "Stop the currently running demo."
  (interactive)
  (with-current-buffer "*kmonad-demo*"
    (kbd-mode-demo-mode 0)
    (kill-buffer-and-window)
    (kbd-mode--kill-demo-process)
    (when kbd-mode-had-kmonad?
      (kbd-mode--start-kmonad))))

(defun kbd-mode-switch ()
  "Switch between the demo window and the config file."
  (interactive)
  (select-window (get-buffer-window
                  (if (and (equal (buffer-name) "*kmonad-demo*")
                           kbd-mode-demo-mode)
                      (get-file-buffer kbd-mode-demo-file)
                    "*kmonad-demo*"))))

;;;; Helper Functions

(defun kbd-mode--create-demo-buffer ()
  "Create the *kmonad-demo* buffer."
  (unless (get-buffer "*kmonad-demo*")
    (display-buffer (get-buffer-create "*kmonad-demo*")
                    '(display-buffer-at-bottom
                      (window-height . 0.15)))))

(defun kbd-mode--find-kbd-file (&optional file)
  "Find the config file.
If the optional argument FILE is given, use it instead.
Otherwise, prompt the user for a choice."
  (if (and file (string= (file-name-extension file) "kbd"))
      file
    (expand-file-name (read-file-name "Choose configuration file"))))

(defun kbd-mode--valid-config? ()
  "Check if the current configuration is valid."
  (let ((command (kbd-mode--get-config-validation-command)))
    (eq 0 (shell-command command))))

(defun kbd-mode--create-kmonad-process ()
  "Start the kmonad demo process in a dedicated buffer."
  (when (get-buffer-process "*kmonad*")
    (kbd-mode--kill-demo-process))
  (start-process "kmonad-emacs" "*kmonad*" "kmonad" kbd-mode-demo-file))

(defun kbd-mode--kill-demo-process ()
  "Kill demo kmonad process, if possible."
  (when (get-buffer-process "*kmonad*")
    (kill-process "*kmonad*")))

(defun kbd-mode--kill-kmonad ()
  "Kill (or suspend) a running kmonad instance.
The command used to kill kmonad is given by the
`kbd-mode-kill-kmonad' variable."
  (if kbd-mode-kill-kmonad
      (shell-command kbd-mode-kill-kmonad)
    (error "To kill the running kmonad instance, customize the `kbd-mode-kill-kmonad' variable!")))

(defun kbd-mode--start-kmonad ()
  "Start (or resume) a new kmonad process.
The command used to start kmonad is given by the
`kbd-mode-start-kmonad' variable."
  (if kbd-mode-kill-kmonad
      (call-process-shell-command
       ;; Force the command to be executed asynchronously.
       (if (eq (aref kbd-mode-start-kmonad
                     (1- (length kbd-mode-start-kmonad)))
               ?&)
           kbd-mode-start-kmonad
         (concat kbd-mode-start-kmonad "&")))
    (error "To restart kmonad, customize the `kbd-mode-start-kmonad' variable!")))

(defun kbd-mode--toggle-demo (&optional _window)
  "Toggle the kmonad demo process.
When the users exits the demo window, kill the demo process and
start a \"normal\" kmonad process instead.  When re-entering the
demo window, do the opposite; i.e., kill the running kmonad
instance and spawn a demo process."
  (cond ((kbd-mode--was-demo?)
         (kbd-mode--kill-demo-process)
         (kbd-mode--start-kmonad))
        ((kbd-mode--valid-config?)
         (kbd-mode--kill-kmonad)
         (kbd-mode--create-kmonad-process))
        (t
         (kbd-mode--start-kmonad)
         (kbd-mode--show-error))))

(defun kbd-mode--was-demo? ()
  "Was the previous buffer the kmonad demo buffer?"
  (equal (window-buffer (previous-window))
         (get-buffer "*kmonad-demo*")))

(defun kbd-mode--show-error ()
  "Show configuration errors in a compilation buffer."
  (when kbd-mode-demo-mode
    (quit-window 'kill "*kmonad-demo*"))
  (compile (kbd-mode--get-config-validation-command)))

(defun kbd-mode--get-config-validation-command ()
  "Get validation command for `kbd-mode-demo-file'."
  (concat "kmonad -d " kbd-mode-demo-file))

;;;; Integration with `compilation-mode'

(add-to-list 'compilation-error-regexp-alist 'kbd)
(add-to-list 'compilation-error-regexp-alist-alist
             '(kbd "^kmonad: Parse error at \\([0-9]+\\):\\([0-9]+\\)" nil 1 2))

(provide 'kbd-mode)

;;; kbd-mode.el ends here
