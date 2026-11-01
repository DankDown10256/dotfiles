;;; -*- lexical-binding: t; -*-

(use-package rust-mode)
(use-package go-mode)
(use-package typescript-mode)
(use-package yaml-mode)
(use-package markdown-mode)

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
         (tsx-ts-mode . eglot-ensure)
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
               '((typescript-mode typescript-ts-mode
                 tsx-ts-mode js-mode js-ts-mode)
                 . ("typescript-language-server" "--stdio"))))

(use-package emmet-mode
  :hook ((html-mode . emmet-mode)
         (mhtml-mode . emmet-mode)
         (web-mode . emmet-mode)
         (css-mode . emmet-mode)
         (tsx-ts-mode . emmet-mode))
  :config
  (setq emmet-move-cursor-between-quotes t))
