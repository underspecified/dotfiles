;;; Bare-minimum config for terminal editing (emacs -nw)

;; Encoding
(prefer-coding-system 'utf-8)

;; UI
(setq inhibit-startup-screen t)
(setq ring-bell-function 'ignore)
(global-font-lock-mode t)
(show-paren-mode t)
(column-number-mode t)

;; Editing
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)
(setq fill-column 80)
(global-set-key (kbd "C-h") 'backward-delete-char)

;; macOS: Option = Meta, Command = Hyper
(when (eq system-type 'darwin)
  (setq mac-option-modifier 'meta)
  (setq mac-command-modifier 'hyper))
