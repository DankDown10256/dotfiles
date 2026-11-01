;;; -*- lexical-binding: t; -*-

(use-package consult
  :bind (("C-x b" . consult-buffer)
         ("C-s" . consult-line)
         ("C-c r" . consult-ripgrep)
         ("C-c i" . consult-imenu)))

(use-package magit
  :bind ("C-x g" . magit-status))

(use-package devdocs
  :bind ("C-h D" . devdocs-lookup))

(use-package elcord
  :config
  (setq elcord-display-buffer-details t)
  (elcord-mode 1))
