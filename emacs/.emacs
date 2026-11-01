;;; -*- lexical-binding: t; -*-
;; Package manager
(require 'package)

(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/") t)

(package-initialize)

(add-to-list 'default-frame-alist
             '(font . "Iosevka Nerd-14"))

(unless (package-installed-p 'evil)
  (unless package-archive-contents
    (package-refresh-contents))
  (package-install 'evil))

(unless (package-installed-p 'gruber-darker-theme)
  (unless package-archive-contents
    (package-refresh-contents))
  (package-install 'gruber-darker-theme))

(menu-bar-mode -1)
(tool-bar-mode -1)
(column-number-mode 1)
(global-display-line-numbers-mode 1)

(load-theme 'gruber-darker t)

(add-to-list 'display-buffer-alist
	     '("\\*compilation\\*"
               (display-buffer-in-side-window)
               (side . bottom)
               (window-height . 0.25)))
(require 'evil)
(evil-mode 1)

(use-package eglot
  :ensure nil
  :hook ((c-mode . eglot-ensure)
         (c++-mode . eglot-ensure)
         (rust-mode . eglot-ensure)
         (python-mode . eglot-ensure)
         (go-mode . eglot-ensure)
         (typescript-mode . eglot-ensure)
         (js-mode . eglot-ensure))
  :config
  (setq eglot-autoshutdown t))

(use-package rust-mode
  :ensure t)

(use-package go-mode
  :ensure t)

(use-package typescript-mode
  :ensure t)

(use-package yaml-mode
  :ensure t)

(use-package markdown-mode
  :ensure t)

(global-font-lock-mode 1)
(setq font-lock-maximum-decoration t)

(use-package eglot
  :ensure nil
  :hook ((c-mode . eglot-ensure)
         (c++-mode . eglot-ensure)
         (rust-mode . eglot-ensure)
         (rust-ts-mode . eglot-ensure)
         (ruby-mode . eglot-ensure)
         (ruby-ts-mode . eglot-ensure)
         (go-mode . eglot-ensure)
         (go-ts-mode . eglot-ensure)
         (python-mode . eglot-ensure)
         (python-ts-mode . eglot-ensure)
         (js-mode . eglot-ensure)
         (js-ts-mode . eglot-ensure)
         (typescript-mode . eglot-ensure)
         (typescript-ts-mode . eglot-ensure)
         (css-mode . eglot-ensure)
         (css-ts-mode . eglot-ensure)
         (html-mode . eglot-ensure)
         (mhtml-mode . eglot-ensure)
         (json-ts-mode . eglot-ensure))
  :config
  (setq eglot-autoshutdown t)

  (add-to-list 'eglot-server-programs
               '((ruby-mode ruby-ts-mode) . ("ruby-lsp")))

  (add-to-list 'eglot-server-programs
               '((python-mode python-ts-mode)
                 . ("basedpyright-langserver" "--stdio")))

  (add-to-list 'eglot-server-programs
               '((go-mode go-ts-mode) . ("gopls")))

  (add-to-list 'eglot-server-programs
               '((rust-mode rust-ts-mode) . ("rust-analyzer")))

  (add-to-list 'eglot-server-programs
               '((typescript-mode typescript-ts-mode js-mode js-ts-mode)
                 . ("typescript-language-server" "--stdio"))))


(dolist (pkg '(corfu emmet-mode))
  (unless (package-installed-p pkg)
    (package-install pkg)))

(require 'corfu)
(setq corfu-auto t
      corfu-auto-delay 0.15
      corfu-auto-prefix 1
      corfu-cycle t)
(global-corfu-mode 1)

(require 'eglot)

(dolist (mode '(c-mode
                c++-mode
                rust-mode
                python-mode
                go-mode
                ruby-mode
                js-mode
                typescript-ts-mode
                tsx-ts-mode
                css-mode
                html-mode))
  (add-hook (intern (concat (symbol-name mode) "-hook"))
            #'eglot-ensure))

(dolist (mode '(html-mode
                mhtml-mode
                web-mode
                css-mode
                tsx-ts-mode))
  (add-hook (intern (concat (symbol-name mode) "-hook"))
            #'emmet-mode))

(setq emmet-move-cursor-between-quotes t)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ai-code-onboarding-auto-show nil)
 '(ai-code-onboarding-seen t)
 '(package-selected-packages
   '(ai-code cape connection consult corfu devdocs doom-game elcord
	     emmet-mode evil go-mode gruber-darker-theme magit-gh
	     markdown-mode orderless projectile-rails rust-mode
	     treemacs typescript-mode vertico vterm yaml-mode)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(use-package corfu
  :ensure t
  :init
  (setq corfu-auto t
        corfu-auto-delay 0.1
        corfu-auto-prefix 1)
  (global-corfu-mode))

(use-package cape
  :ensure t
  :init
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-file))
(use-package recentf
  :ensure nil
  :init
  (setq recentf-max-saved-items 200)
  (recentf-mode 1))

(use-package vertico
  :ensure t
  :init
  (vertico-mode 1))

(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic)))

(use-package consult
  :ensure t
  :config
  (evil-define-key 'normal 'global
    (kbd "SPC f r") #'consult-recent-file))
(use-package elcord
  :ensure t
  :config
  (setq elcord-display-buffer-details t)
  (elcord-mode 1))

(use-package consult
  :ensure t
  :bind
  (("C-x b" . consult-buffer)
   ("C-s" . consult-line)
   ("C-c r" . consult-ripgrep)
   ("C-c i" . consult-imenu)))

(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status))

(use-package magit-gh
  :ensure t
  :after magit)

(global-set-key (kbd "C-h D") 'devdocs-lookup)
