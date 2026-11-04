;;; -*- lexical-binding: t; -*-

(use-package evil
  :config
  (evil-mode 1)

  (define-key evil-normal-state-map (kbd "C-x X") #'quit-window)
  (define-key evil-insert-state-map (kbd "C-x X") #'quit-window))
