;;; -*- lexical-binding: t; -*-

(electric-pair-mode 1)
(column-number-mode 1)
(global-display-line-numbers-mode 1)
(global-font-lock-mode 1)

(setq font-lock-maximum-decoration t)

(use-package recentf
  :ensure nil
  :init
  (setq recentf-max-saved-items 200)
  (recentf-mode 1))

(add-to-list 'display-buffer-alist
             '("\\*compilation\\*"
               (display-buffer-in-side-window)
               (side . bottom)
               (window-height . 0.25)))
