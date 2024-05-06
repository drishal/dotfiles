;;; tokyonight-storm-theme.el --- TokyoNight Storm. -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(eval-and-compile
  (unless (and (fboundp 'require-theme)
               load-file-name
               (equal (file-name-directory load-file-name)
                      (expand-file-name "themes/" data-directory))
               (require-theme 'tokyonight-themes t))
    (require 'tokyonight-themes))

  ;;;###theme-autoload
  (deftheme tokyonight-storm
    "TokyoNight Storm."
    :background-mode 'dark
    :kind 'color-scheme
    :family 'tokyonight)

  (defconst tokyonight-storm-palette
    '((bg-dark . "#1f2335")
      (bg . "#24283b")
      (bg-hl . "#292e42")
      (terminal-black . "#414868")
      (fg . "#c0caf5")
      (fg-dark . "#a9b1d6")
      (fg-gutter . "#3b4261")
      (white . "#ffffff")
      (comment . "#565f89")
      (dark3 . "#545c7e")
      (dark5 . "#737aa2")
      (blue0 . "#3d59a1")
      (blue . "#7aa2f7")
      (blue1 . "#2ac3de")
      (blue2 . "#0db9d7")
      (blue5 . "#89ddff")
      (blue6 . "#b4f9f8")
      (blue7 . "#394b70")
      (cyan . "#7dcfff")
      (magenta . "#bb9af7")
      (magenta2 . "#ff007c")
      (purple . "#9d7cd8")
      (orange . "#ff9e64")
      (yellow . "#e0af68")
      (green . "#9ece6a")
      (green1 . "#73daca")
      (green2 . "#41a6b5")
      (teal . "#1abc9c")
      (red . "#f7768e")
      (red1 . "#db4b4b"))
    "TokyoNight storm palette.")

  (defcustom tokyonight-storm-palette-overrides nil
    "Overrides for `tokyonight-storm-palette'."
    :group 'tokyonight-themes
    :type 'alist)

  (tokyonight-themes-theme tokyonight-storm
                           tokyonight-storm-palette
                           tokyonight-storm-palette-overrides)

  (provide-theme 'tokyonight-storm))
;;; tokyonight-storm-theme.el ends here
