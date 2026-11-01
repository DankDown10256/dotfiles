;;; -*- lexical-binding: t; -*-

(use-package evil
  :config
  (evil-mode 1)

  (evil-define-key 'normal 'global
    (kbd "SPC w h") #'other-window
    (kbd "SPC w l") (lambda ()
                      (interactive)
                      (other-window -1))
    (kbd "SPC w q") #'delete-window

    (kbd "SPC .") #'find-file
    (kbd "SPC b b") #'switch-to-buffer
    (kbd "SPC f r") #'consult-recent-file))
