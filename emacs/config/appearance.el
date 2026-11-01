;;; -*- lexical-binding: t; -*-

(menu-bar-mode -1)
(tool-bar-mode -1)

(add-to-list 'default-frame-alist
             '(font . "Iosevka Nerd-9"))
(set-face-attribute 'default nil
                    :family "IosevkaTerm Nerd Font Mono"
                    :height 110)

(use-package gruber-darker-theme
  :config
  (load-theme 'gruber-darker t))

(use-package hl-todo
  :config
  (setq hl-todo-keyword-faces
        '(("TODO"   . "#FF0000")
          ("FIXME"  . "#FF0000")
          ("DEBUG"  . "#A020F0")
          ("GOTCHA" . "#FF4500")
          ("STUB"   . "#1E90FF")))
  (global-hl-todo-mode 1))
