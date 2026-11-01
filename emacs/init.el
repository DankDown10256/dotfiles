;;; -*- lexical-binding: t; -*-

(add-to-list 'load-path
             (expand-file-name "config" user-emacs-directory))

(setq custom-file
      (expand-file-name "custom.el" user-emacs-directory))

(load "packages")
(load "core")
(load "appearance")
(load "completion")
(load "development")
(load "tools")
(load "keymaps")

(when (file-exists-p custom-file)
  (load custom-file))

(use-package dashboard
  :config
  (setq dashboard-startup-banner (seq-random-elt '(official logo))
	dashboard-center-content t
	dashboard-vertically-center-content t
	dashboard-items '((recents . 5)
                          (projects . 5))
	dashboard-set-heading-icons t
	dashboard-set-file-icons t
	dashboard-banner-logo-title (format-time-string "Today is %A")) 
  
  (dashboard-setup-startup-hook))

