;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Drishal Ballaney"
      user-mail-address "drishalballeny@gmail.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
(setq doom-font (font-spec :family "FiraCode Nerd Font" :size 16)
      doom-variable-pitch-font (font-spec :family "FiraCode Nerd Font" :size 16)
      doom-big-font (font-spec :family "FiraCode Nerd Font" :size 24))

;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:

(setq doom-theme 'doom-dracula)
;;
                                        ;(setq load-theme 'dracula)
                                        ;(setq org-hide-emphasis-markers t)


;; (after! org (setq org-hide-emphasis-markers t))
(setq org-hide-emphasis-markers t)

;;(setq doom-theme 'doom-acario-light)
;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

(setq x-select-enable-clipboard-manager nil)
(setq confirm-kill-emacs nil)
;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;;
;(setq doom-font (font-spec :family "Hack Nerd Font" :size 15 :weight 'normal)
;        doom-variable-pitch-font (font-spec :family "Hack Nerd Font" :size 15))

;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
;; OPACITY
;; set transparency
;; (set-frame-parameter (selected-frame) 'alpha '(90 90))
;; (add-to-list 'default-frame-alist '(alpha 90 90))
 (after! company
   (setq company-idle-delay 0.0))
(setq-default left-margin-width 1 right-margin-width 1 top-margin-width 5  bottom-margin-width 5)
(set-window-buffer nil (current-buffer))
(setq header-line-format " ")
;;(require 'smtpmail)
(add-hook 'org-mode-hook 'org-appear-mode)

;(package! $pkgname :recipe (:build (:not native-compile)))
;; (package! $pkgname :recipe (:build (:not native-compile)))
(setq evil-want-fine-undo t)
;; (setq company-dabbrev-downcase 0)
;; (setq company-idle-delay 0)
(setq-hook! 'haskell-mode-hook lsp-enable-indentation nil)
;;  powerline
;; (require 'powerline)
;; (powerline-vim-theme)
(blink-cursor-mode 1)
(setq vterm-buffer-name "vterm")
(set-popup-rule! "^vterm" :size 0.40 :vslot -4 :select t :quit nil :ttl 0)
;; (defadvice! dont-fontify-my-thangs (orig-fn &rest args)
;;   :around '(org-superstar-mode org-fancy-priorities-mode)
;;   (letf! ((#'font-lock-ensure #'ignore)
;;           (#'font-lock-flush #'ignore)
;;           (#'font-lock-fontify-buffer #'ignore))
;;     (apply orig-fn args)))
;; using org babel tangle for completion
;; hook to automatically tangle on save
;; (defun f2k--tangle-org-on-save-h ()
;;   "Tangle literate config on save."
;;   (if (string= (buffer-name) "README.org")
;;       (org-babel-tangle-file "README.org" "config.py")))

;; (add-hook 'after-save-hook #'f2k--tangle-org-on-save-h)
;; hook to automatically tangle on save
(defun f2k--tangle-all-org-on-save-h ()
  "Tangle org files on save."
  (if (string= (file-name-extension (buffer-file-name)) "org")
      (org-babel-tangle)))

(add-hook 'after-save-hook #'f2k--tangle-all-org-on-save-h)
