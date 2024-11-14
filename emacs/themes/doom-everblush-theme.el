;;; doom-everblush-theme.el --- Based on everblush colorscheme by Mangeshrex -*- lexical-binding: t; no-byte-compile: t; -*-

;; Maintainer: Mangeshrex
;; Version: 0.1.0
;; Homepage: https://github.com/Everblush/doomemacs
;; Package-Requires: ((emacs "24.1") (doom-themes "2.3.0"))


;;; Commentary:
;;
;;; Code:

(require 'doom-themes)


;;
;;; Variables

(defgroup doom-everblush-theme nil
  "Options for the `doom-everblush' theme."
  :group 'doom-themes)

(defcustom doom-everblush-brighter-modeline nil
  "If non-nil, more vivid colors will be used to style the mode-line."
  :group 'doom-everblush-theme
  :type 'boolean)

(defcustom doom-everblush-brighter-comments nil
  "If non-nil, comments will be highlighted in more vivid colors."
  :group 'doom-everblush-theme
  :type 'boolean)

(defcustom doom-everblush-padded-modeline doom-themes-padded-modeline
  "If non-nil, adds a 4px padding to the mode-line.
Can be an integer to determine the exact padding."
  :group 'doom-everblush-theme
  :type '(choice integer boolean))


;;
;;; Theme definition

(def-doom-theme doom-everblush
  "A beautiful and dark vim colorscheme ported to doom emacs."

  ;; name        default   256           16
  ((bg         '("#141b1e" "#141b1e"      nil  )) ;
   (fg         '("#dadada" "#dadada"    "brightwhite"  )) ;

   ;; These are off-color variants of bg/fg, used primarily for `solaire-mode',
   ;; but can also be useful as a basis for subtle highlights (e.g. for hl-line
   ;; or region), especially when paired with the `doom-darken', `doom-lighten',
   ;; and `doom-blend' helper functions.
   (bg-alt     '("#141b1e" "#141b1e"     nil        )) ;
   (fg-alt     '("#dadada" "#dadada"    "white"        )) ;

   ;; These should represent a spectrum from bg to fg, where base0 is a starker
   ;; bg and base8 is a starker fg. For example, if bg is light grey and fg is
   ;; dark grey, base0 should be white and base8 should be black.
   (base0      '("#141b1e" "#141b1e"     "black"        )) ;
   (base1      '("#232a2d" "#232a2d"     "brightblack"  )) ;
   (base2      '("#232a2d" "#232a2d"     "brightblack"  )) ;
   (base3      '("#2d3437" "#2d3437"     "brightblack"  )) ;
   (base4      '("#363d3f" "#363d3f"     "brightblack"  )) ;
   (base5      '("#363d3f" "#363d3f"     "brightblack"  )) ;
   (base6      '("#2d3437" "#2d3437"     "brightblack"  )) ;
   (base7      '("#2d3437" "#2d3437"     "brightblack"  )) ;
   (base8      '("#bcd3c2" "#bcd3c2"     "white"        )) ;

   (grey       base4)
   (red        '("#e57474" "#e57474" "red"          ))
   (orange     '("#ef7e7e" "#ef7e7e" "brightred"    ))
   (green      '("#8ccf7e" "#8ccf7e" "green"        ))
   (teal       '("#96d988" "#96d988" "brightgreen"  ))
   (yellow     '("#e5c76b" "#e5c76b" "yellow"       ))
   (blue       '("#71baf2" "#71baf2" "brightblue"   ))
   (dark-blue  '("#67b0e8" "#67b0e8" "blue"         ))
   (magenta    '("#ce89df" "#ce89df" "brightmagenta"))
   (violet     '("#c47fd5" "#c47fd5" "magenta"      ))
   (cyan       '("#67cbe7" "#67cbe7" "brightcyan"   ))
   (dark-cyan  '("#6cbfbf" "#6cbfbf" "cyan"         ))

   ;; These are the "universal syntax classes" that doom-themes establishes.
   ;; These *must* be included in every doom themes, or your theme will throw an
   ;; error, as they are used in the base theme defined in doom-themes-base.
   (highlight      blue)
   (vertical-bar   (doom-darken base1 0.1))
   (selection      dark-blue)
   (builtin        magenta)
   ;;(comments       (if doom-everblush-brighter-comments dark-cyan base5))
   (comments       grey)
   (doc-comments   (doom-lighten (if doom-everblush-brighter-comments dark-cyan base5) 0.25))
   (constants      violet)
   (functions      orange)
   (keywords       teal)
   (methods        cyan)
   (operators      blue)
   (type           yellow)
   (strings        green)
   (variables      orange)
;;   (variables      dark-blue)
   (numbers        dark-cyan)
   (region         `(,(doom-lighten (car bg-alt) 0.15) ,@(doom-lighten (cdr base1) 0.35)))
   (error          red)
   (warning        yellow)
   (success        green)
   (vc-modified    orange)
   (vc-added       green)
   (vc-deleted     red)

   ;; These are extra color variables used only in this theme; i.e. they aren't
   ;; mandatory for derived themes.
   (modeline-fg              fg)
   (modeline-fg-alt          base5)
   (modeline-bg              (if doom-everblush-brighter-modeline
                                 (doom-darken blue 0.45)
                               (doom-darken bg-alt 0.1)))
   (modeline-bg-alt          (if doom-everblush-brighter-modeline
                                 (doom-darken blue 0.475)
                               `(,(doom-darken (car bg-alt) 0.15) ,@(cdr bg))))
   (modeline-bg-inactive     `(,(car bg-alt) ,@(cdr base1)))
   (modeline-bg-inactive-alt `(,(doom-darken (car bg-alt) 0.1) ,@(cdr bg)))

   (-modeline-pad
    (when doom-everblush-padded-modeline
      (if (integerp doom-everblush-padded-modeline) doom-everblush-padded-modeline 4))))


  ;;;; Base theme face overrides
  (((line-number &override) :foreground base4)
   ((line-number-current-line &override) :foreground fg)
   ((font-lock-comment-face &override)
    :background (if doom-everblush-brighter-comments (doom-lighten bg 0.05)))
   (mode-line
    :background modeline-bg :foreground modeline-fg
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg)))
   (mode-line-inactive
    :background modeline-bg-inactive :foreground modeline-fg-alt
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-inactive)))
   (mode-line-emphasis :foreground (if doom-everblush-brighter-modeline base8 highlight))

   ;;;; css-mode <built-in> / scss-mode
   (css-proprietary-property :foreground orange)
   (css-property             :foreground green)
   (css-selector             :foreground blue)
   ;;;; doom-modeline
   (doom-modeline-bar :background (if doom-everblush-brighter-modeline modeline-bg highlight))
   (doom-modeline-buffer-file :inherit 'mode-line-buffer-id :weight 'bold)
   (doom-modeline-buffer-path :inherit 'mode-line-emphasis :weight 'bold)
   (doom-modeline-buffer-project-root :foreground green :weight 'bold)
   ;;;; elscreen
   (elscreen-tab-other-screen-face :background "#353a42" :foreground "#1e2022")
   ;;;; ivy
   (ivy-current-match :background dark-blue :distant-foreground base0 :weight 'normal)
   ;;;; LaTeX-mode
   (font-latex-math-face :foreground green)
   ;;;; markdown-mode
   (markdown-markup-face :foreground base5)
   (markdown-header-face :inherit 'bold :foreground red)
   ((markdown-code-face &override) :background (doom-lighten base3 0.05))
   ;;;; rjsx-mode
   (rjsx-tag :foreground red)
   (rjsx-attr :foreground orange)
   ;;;; solaire-mode
   (solaire-mode-line-face
    :inherit 'mode-line
    :background modeline-bg-alt
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-alt)))
   (solaire-mode-line-inactive-face
    :inherit 'mode-line-inactive
    :background modeline-bg-inactive-alt
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-inactive-alt))))

  ;;;; Base theme variable overrides-
  ;; ()
  )

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))
;;; doom-everblush-theme.el ends here
