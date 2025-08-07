;;; modify load paths
(let ((default-directory "~/.emacs.d/site-lisp/"))
  (normal-top-level-add-to-load-path '("."))
  (normal-top-level-add-subdirs-to-load-path))

;;; Emacs Lisp Package Archive: http://emacswiki.org/emacs/ELPA
(setq package-archives '(("gnu" . "http://elpa.gnu.org/packages/")
			 ("marmalade" . "http://marmalade-repo.org/packages/")
			 ("melpa" . "http://melpa.milkbox.net/packages/")))
(cond
  ((>= 24 emacs-major-version)
   (require 'package)
   (package-initialize)
   (add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/"))
  (package-refresh-contents)))

;; initialize packages before everything else so we can reference them
(package-initialize)

;;; load local .el files
(cond ((eq system-type 'darwin) (load "osx.el" 'noerror))
      ((eq system-type 'gnu/linux) (load "linux.el" 'noerror)))

;;; python settings
;(load "custom-python.el" 'noerror)

;; AucTex
;(load "auctex.el" 'noerror)
;(load "yatex.el" 'noerror)
;(require 'tex-site)

;;; markdown mode
(setq auto-mode-alist
   (append (list '("\\.markdown" . markdown-mode)
		 '("\\.markdn" . markdown-mode)
		 '("\\.md" . markdown-mode)
		 '("\\.mdml" . markdown-mode)
		 '("\\.mdt" . markdown-mode)
		 '("\\.mdown" . markdown-mode)
		 '("\\.mdwn" . markdown-mode)
		 '("\\.mkd" . markdown-mode)
		 '("\\.text" . markdown-mode))
	 auto-mode-alist))

;;; buffer/process encoding
(setq buffer-file-coding-system 'utf-8)
(setq default-buffer-file-coding-system 'utf-8)
(setq default-coding-systems 'utf-8)
(setq default-keyboard-coding-system 'utf-8)
(setq default-terminal-coding-system 'utf-8)
(prefer-coding-system 'utf-8)

;; hide annoying splash screen
;(setq inhibit-splash-screen t)

;;; delete is always backspace
(global-set-key (kbd "C-h") 'backward-delete-char)

;;; Search stuff
(setq search-highlight t)
(setq re-search-highlight t)
(setq isearch-highlight t)

;;;  egrep, eval
(setq enable-local-eval t)
(setq grep-command "egrep -n -i ")

;;; font lock
(global-font-lock-mode t)
(setq font-lock-maximum-decoration t)

;;; filling
(setq fill-column 80)
(add-hook 'text-mode-hook 'turn-on-auto-fill)

;;; flyspell settings
(setq-default ispell-list-command "list")
(autoload 'flyspell-mode "flyspell" "On-the-fly ispell." t)
(add-hook 'text-mode-hook 'flyspell-mode); enable flyspell mode for text-mode
(add-hook 'latex-mode-hook 'flyspell-mode); enable flyspell mode for text-mode
(add-hook 'mail-send-hook 'flyspell-mode-off)
(mapcar (lambda (mode-hook) (add-hook mode-hook 'flyspell-prog-mode))
	'(c-mode-common-hook R-mode-hook emacs-lisp-mode-hook python-mode-hook))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(blink-cursor-mode nil)
 '(custom-enabled-themes (quote (sanityinc-solarized-light)))
 '(custom-safe-themes
   (quote
    ("4cf3221feff536e2b3385209e9b9dc4c2e0818a69a1cdb4b522756bcdf4e00a4" "8db4b03b9ae654d4a57804286eb3e332725c84d7cdab38463cb6b97d5762ad26" "a8245b7cc985a0610d71f9852e9f2767ad1b852c2bdea6f4aadc12cce9c4d6d0" "d677ef584c6dfc0697901a44b885cc18e206f05114c8a3b7fde674fce6180879" "fc5fcb6f1f1c1bc01305694c59a1a861b008c534cae8d0e48e4d5e81ad718bc6" "1e7e097ec8cb1f8c3a912d7e1e0331caeed49fef6cff220be63bd2a6ba4cc365" default)))
 '(frame-background-mode (quote dark))
 '(haskell-mode-hook (quote (turn-on-haskell-indentation)))
 '(inhibit-startup-screen t)
 '(mac-emulate-three-button-mouse t)
 '(mac-mouse-wheel-mode t)
 '(ns-pop-up-frames nil)
 '(package-selected-packages
   (quote
    (color-theme-sanityinc-solarized solarized-theme 0blayout scala-mode2 rainbow-mode markdown-mode ghci-completion ghc ensime auctex)))
 '(quack-default-program "csi")
 '(quack-fontify-style (quote emacs))
 '(quack-pretty-lambda-p t)
 '(quack-smart-open-paren-p t)
 '(show-paren-mode t)
 '(tab-stop-list
   (quote
    (4 8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 76 80 84 88 92 96 100 104 108 112 116 120)))
 '(text-mode-hook (quote (text-mode-hook-identify)))
 '(tool-bar-mode nil))

;;; disable that ear-fucking bell once and for all!
(setq ring-bell-function 'ignore)

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;; Auto-Dark-Emacs is an auto changer between 2 themes, dark/light, respecting the
;; overall settings of MacOS

;; Set your themes here
(set 'darktheme 'sanityinc-solarized-dark)
(set 'lightheme 'sanityinc-solarized-light)

(set 'thebeforestate "initial") 

(run-with-timer 0 1 (lambda ()
  ;; Get's MacOS dark mode state
  (if (string= (shell-command-to-string "printf %s \"$( osascript -e \'tell application \"System Events\" to tell appearance preferences to return dark mode\' )\"") "true")
      	       (progn
		    (set 'thenowstate t)
		     )
		(set 'thenowstate nil)
		)

  ;; Verifies if Darkmode is changed since last checked
  (if (string= thenowstate thebeforestate)
      ;; If nothing is changed
      (progn

	)

      ;; If something is changed
      (if (string= thenowstate "t")
	  (progn
	    (load-theme darktheme t)
	    (disable-theme lightheme)
	    )
	(load-theme lightheme t)
        (disable-theme darktheme)
	)
      )
  (set 'thebeforestate thenowstate)
  )
)

;; Keybonds
(global-set-key [(hyper a)] 'mark-whole-buffer)
(global-set-key [(hyper c)] 'kill-ring-save)
(global-set-key [(hyper l)] 'goto-line)
(global-set-key [(hyper q)] 'save-buffers-kill-emacs)
(global-set-key [(hyper s)] 'save-buffer)
(global-set-key [(hyper v)] 'yank)
(global-set-key [(hyper w)]
                (lambda () (interactive) (delete-window)))
(global-set-key [(hyper z)] 'undo)

;; mac switch meta key
(defun mac-switch-meta nil 
  "switch meta between Option and Command"
  (interactive)
  (if (eq mac-option-modifier nil)
      (progn
	(setq mac-option-modifier 'meta)
	(setq mac-command-modifier 'hyper)
	)
    (progn 
      (setq mac-option-modifier nil)
      (setq mac-command-modifier 'meta)
      )
    )
  )

;;; make option into meta key
(setq mac-option-modifier 'meta)
(setq mac-command-modifier 'hyper)

;;; save window position
(desktop-save-mode 1)
