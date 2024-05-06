;;; tokyonight-night-theme.el --- TokyoNight Night. -*- lexical-binding: t -*-
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
  (deftheme tokyonight-night
    "TokyoNight Night."
    :background-mode 'dark
    :kind 'color-scheme
    :family 'tokyonight)

  (defconst tokyonight-night-palette
    '((bg-dark . "#16161e")
      (bg . "#1a1b26")
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
      (blue1 . "#65bcff")
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
    "TokyoNight night palette.")

  (defcustom tokyonight-night-palette-overrides nil
    "Overrides for `tokyonight-night-palette'."
    :group 'tokyonight-themes
    :type 'alist)

  (tokyonight-themes-theme tokyonight-night
                           tokyonight-night-palette
                           tokyonight-night-palette-overrides)

  (provide-theme 'tokyonight-night))
;;; tokyonight-night-theme.el ends here
