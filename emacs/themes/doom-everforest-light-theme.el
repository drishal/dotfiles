;;; doom-everforest-light-theme.el --- inspired by Everforest -*- no-byte-compile: t; -*-
;;; https://github.com/sainnhe/everforest
(require 'doom-themes)

;;
(defgroup doom-everforest-light-theme nil
  "Options for doom-themes"
  :group 'doom-themes)

(defcustom doom-everforest-light-brighter-modeline nil
  "If non-nil, more vivid colors will be used to style the mode-line."
  :group 'doom-everforest-light-theme
  :type 'boolean)

(defcustom doom-everforest-light-brighter-comments nil
  "If non-nil, comments will be highlighted in more vivid colors."
  :group 'doom-everforest-light-theme
  :type 'boolean)

(defcustom doom-everforest-light-comment-bg doom-everforest-light-brighter-comments
  "If non-nil, comments will have a subtle, darker background. Enhancing their
legibility."
  :group 'doom-everforest-light-theme
  :type 'boolean)

(defcustom doom-everforest-light-padded-modeline doom-themes-padded-modeline
  "If non-nil, adds a 4px padding to the mode-line. Can be an integer to
determine the exact padding."
  :group 'doom-everforest-light-theme
  :type '(choice integer boolean))

(defcustom doom-everforest-light-background nil
  "Choice between \"soft\", \"medium\" and \"hard\" background contrast.
Defaults to \"soft\""
  :group 'doom-everforest-light-theme
  :type 'string)

(defcustom doom-everforest-light-palette nil
  "Choose between \"material\", \"mix\" and \"original\" color palette.
Defaults to \"material\""
  :group 'doom-everforest-light-theme
  :type 'string)

(defcustom doom-everforest-light-dired-height 1.15
  "Font height for dired buffers"
  :group 'doom-everforest-light-theme
  :type 'float)
;; colors from
;; https://github.com/sainnhe/everforest/blob/master/autoload/everforest.vim
(cond
 ((equal doom-everforest-light-background "hard")
  (setq efl/bg           "#fffbef"       ;; bg0
        efl/bg-alt       "#f2efdf"       ;; bg1
        efl/base0        "#f0eed9"       ;; bg2
        efl/base1        "#e9e8d2"       ;; bg3
        efl/base2        "#e1ddcb"       ;; bg4
        efl/base3        "#bec5b2"       ;; bg5
        efl/base4        "#edf0cd"       ;; bg_visual
        efl/base5        "#a6b0a0"       ;; grey0
        efl/base6        "#939f91"       ;; grey1
        efl/base7        "#829181"       ;; grey2
        efl/base8        "#a6b0a0"))     ;; grey0
 ((equal doom-everforest-light-background "medium")
  (setq efl/bg           "#fdf6e3"       ;; bg0
        efl/bg-alt       "#efebd4"       ;; bg1
        efl/base0        "#edead5"       ;; bg2
        efl/base1        "#e4e1cd"       ;; bg3
        efl/base2        "#dfdbc8"       ;; bg4
        efl/base3        "#bdc3af"       ;; bg5
        efl/base4        "#eaedc8"       ;; bg_visual
        efl/base5        "#a6b0a0"       ;; grey0
        efl/base6        "#939f91"       ;; grey1
        efl/base7        "#829181"       ;; grey2
        efl/base8        "#a6b0a0"))     ;; grey0
 (t
  (setq efl/bg           "#f3ead3"       ;; bg0
        efl/bg-alt       "#e5dfc5"       ;; bg1
        efl/base0        "#e9e5cf"       ;; bg2
        efl/base1        "#e1ddc9"       ;; bg3
        efl/base2        "#dcd8c4"       ;; bg4
        efl/base3        "#b9c0ab"       ;; bg5
        efl/base4        "#e6e9c4"       ;; bg_visual
        efl/base5        "#a6b0a0"       ;; grey0
        efl/base6        "#939f91"       ;; grey1
        efl/base7        "#829181"       ;; grey2
        efl/base8        "#a6b0a0")))    ;; grey0


(def-doom-theme doom-everforest-light
  "Everforest light variant"
  ;; name        default        256       16
  ((bg         `(,efl/bg         nil       nil            ))
   (bg-alt     `(,efl/bg-alt     nil       nil            ))
   (base0      `(,efl/base0      "black"   "black"        ))
   (base1      `(,efl/base1      "#1e1e1e" "brightblack"  ))
   (base2      `(,efl/base2      "#2e2e2e" "brightblack"  ))
   (base3      `(,efl/base3      "#262626" "brightblack"  ))
   (base4      `(,efl/base4      "#3f3f3f" "brightblack"  ))
   (base5      `(,efl/base5      "#525252" "brightblack"  ))
   (base6      `(,efl/base6      "#6b6b6b" "brightblack"  ))
   (base7      `(,efl/base7      "#979797" "brightblack"  ))
   (base8      `(,efl/base8      "#dfdfdf" "white"        ))
   (fg         '("#5c6a72" "#bfbfbf" "brightwhite"        ))
   (fg-alt     '("#5f6d67" "#2d2d2d" "white"              )) ;; bg5 dark soft

   (grey       base4)
   (red        '("#f85552" "#ff6655" "red"          ))
   (orange     '("#f57d26" "#dd8844" "brightred"    ))
   (green      '("#8da101" "#99bb66" "green"        ))
   (teal       '("#35a77c" "#44b9b1" "brightgreen"  )) ;; aqua
   (yellow     '("#dfa000" "#ECBE7B" "yellow"       ))
   (blue       '("#3a94c5" "#51afef" "brightblue"   ))
   (dark-blue  '("#65a199" "#2257A0" "blue"         )) ;; own
   (magenta    '("#df69ba" "#c678dd" "brightmagenta")) ;; purple
   (violet     '("#df69ba" "#a9a1e1" "magenta"      )) ;; purple
   (cyan       '("#35a77c" "#46D9FF" "brightcyan"   )) ;; aqua
   (dark-cyan  '("#278c66" "#5699AF" "cyan"         )) ;; own

   ;; face categories -- required for all themes
   (highlight      blue)
   (vertical-bar   (doom-darken base1 0.1))
   (selection      dark-blue)
   (builtin        magenta)
   (comments       (if doom-everforest-light-brighter-comments cyan
                     (doom-blend magenta cyan 0.65)))
   (doc-comments   (doom-darken (if doom-everforest-light-brighter-comments
                                    dark-cyan green) 0.2))
   (constants      magenta)
   (functions      cyan)
   (keywords       (doom-darken teal 0.15))
   (methods        cyan)
   (operators      blue)
   (type           orange)
   (strings        green)
   (variables      blue)
   (numbers        magenta)
   (region         `(,(doom-lighten (car bg-alt) 0.15) ,@(doom-lighten (cdr base1) 0.35)))
   (error          red)
   (warning        yellow)
   (success        green)
   (vc-modified    orange)
   (vc-added       green)
   (vc-deleted     red)

   ;; custom categories
   (hidden     `(,(car bg) "black" "black"))
   (-modeline-bright doom-everforest-light-brighter-modeline)
   (-modeline-pad
    (when doom-everforest-light-padded-modeline
      (if (integerp doom-everforest-light-padded-modeline) doom-everforest-light-padded-modeline 4)))

   (modeline-fg     fg)
   (modeline-fg-alt fg-alt)

   (modeline-bg
    (if -modeline-bright
        (doom-darken blue 0.475)
      `(,(doom-darken (car bg-alt) 0.15) ,@(cdr base0))))
   (modeline-bg-l
    (if -modeline-bright
        (doom-darken blue 0.45)
      `(,(doom-darken (car bg-alt) 0.1) ,@(cdr base0))))
   (modeline-bg-inactive   `(,(doom-darken (car bg-alt) 0.1) ,@(cdr bg-alt)))
   (modeline-bg-inactive-l `(,(car bg-alt) ,@(cdr base1))))


  ;; --- extra faces ------------------------
  ((elscreen-tab-other-screen-face :background "#353a42" :foreground "#1e2022")

   (evil-goggles-default-face :inherit 'region :background (doom-blend region bg 0.5))

   ((line-number &override) :foreground base5)
   ((line-number-current-line &override) :foreground fg)

   (font-lock-comment-face
    :foreground comments
    :background (if doom-everforest-light-comment-bg (doom-lighten bg 0.05)))
   (font-lock-doc-face
    :inherit 'font-lock-comment-face
    :foreground doc-comments)

   (mode-line
    :background modeline-bg :foreground modeline-fg
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg)))
   (mode-line-inactive
    :background modeline-bg-inactive :foreground modeline-fg-alt
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-inactive)))
   (mode-line-emphasis
    :foreground (if -modeline-bright base8 highlight))

   (solaire-mode-line-face
    :inherit 'mode-line
    :background modeline-bg-l
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-l)))
   (solaire-mode-line-inactive-face
    :inherit 'mode-line-inactive
    :background modeline-bg-inactive-l
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-inactive-l)))

   ;; Doom modeline
   (doom-modeline-bar :background (if -modeline-bright modeline-bg highlight))
   (doom-modeline-buffer-file :inherit 'mode-line-buffer-id :weight 'bold)
   (doom-modeline-buffer-path :inherit 'mode-line-emphasis :weight 'bold)
   (doom-modeline-buffer-project-root :foreground green :weight 'bold)

   ;; ivy-mode
   (ivy-current-match :background dark-blue :distant-foreground bg :weight 'normal)

   ;; --- major-mode faces -------------------
   ;; column indicator
   (fill-column-indicator :foreground bg-alt :background bg-alt)

   ;; css-mode / scss-mode
   (css-proprietary-property :foreground orange)
   (css-property             :foreground green)
   (css-selector             :foreground blue)

   ;; cursor
   (cursor :foreground fg :background blue)

   ;; dired
   (diredfl-compressed-file-name :height doom-everforest-light-dired-height
                    :foreground yellow)
   (diredfl-dir-heading :height doom-everforest-light-dired-height
                        :foreground teal)
   (diredfl-dir-name :height doom-everforest-light-dired-height
                     :foreground blue)
   (diredfl-deletion :height doom-everforest-light-dired-height
                     :foreground red :background (doom-lighten red 0.55))
   (diredfl-deletion-file-name :foreground red
                               :background (doom-lighten red 0.55))
   (diredfl-file-name :height doom-everforest-light-dired-height
                      :foreground fg)
   (dired-flagged :height doom-everforest-light-dired-height
                    :foreground red :background (doom-lighten red 0.55))
   (diredfl-symlink :height doom-everforest-light-dired-height
                    :foreground magenta)

   ;; ein
   (ein:basecell-input-area-face :background bg)

   ;; eshell
   (+eshell-prompt-git-branch :foreground cyan)

   ;; evil
   (evil-ex-lazy-highlight :foreground fg :background (doom-lighten orange 0.3))
   (evil-snipe-first-match-face :foreground bg :background orange)

   ;; ivy
   (ivy-current-match :foreground blue :background bg)
   (ivy-minibuffer-match-face-2 :foreground blue :background bg)

   ;; LaTeX-mode
   (font-latex-math-face :foreground (doom-lighten green 0.15))
   (font-latex-script-char :foreground dark-blue)

   ;; lsp
   (lsp-face-highlight-read :foreground fg-alt
                           :background (doom-lighten dark-blue 0.3))
   (lsp-face-highlight-textual :foreground fg-alt
                           :background (doom-lighten dark-blue 0.3))
   (lsp-face-highlight-write :foreground fg-alt
                             :background (doom-lighten dark-blue 0.3))
   (lsp-lsp-flycheck-info-unnecessary-face
    :foreground (doom-lighten yellow 0.12))

   ;; magit
   (magit-section-heading :foreground blue :weight 'bold)

   ;; markdown-mode
   (markdown-markup-face :foreground base5)
   (markdown-header-face :inherit 'bold :foreground red)
   ((markdown-code-face &override) :background (doom-lighten base3 0.05))

   ;; org-mode
   (org-hide :foreground hidden)
   (solaire-org-hide-face :foreground hidden)
   (org-drawer :foreground (doom-lighten yellow 0.15))
   (org-document-info :foreground blue :weight 'bold)
   (org-document-info-keyword :foreground blue)
   (org-document-title :foreground blue)
   (org-block-begin-line :foreground dark-cyan
                         :background (doom-blend bg teal 0.85))
   (org-block-end-line :foreground dark-cyan
                         :background (doom-blend bg teal 0.85))
   (org-block :foreground fg :background (doom-blend bg teal 0.85))
   (org-meta-line :foreground cyan)
   (org-level-1 :foreground magenta :weight 'semi-bold :height 1.4)
   (org-level-2 :foreground cyan :weight 'semi-bold :height 1.2)
   (org-level-3 :foreground green :weight 'semi-bold :height 1.1)
   (org-level-4 :foreground yellow :weight 'semi-bold)
   (org-level-5 :foreground violet :weight 'semi-bold)
   (org-level-6 :foreground dark-cyan :weight 'semi-bold)
   (org-level-7 :foreground (doom-lighten green 0.15) :weight 'semi-bold)
   (org-level-8 :foreground (doom-lighten yellow 0.15) :weight 'semi-bold)

   ;; org-ref
   (org-ref-ref-face :foreground magenta)

   ;; org-roam
   (org-roam-title :foreground orange :weight 'semi-bold)

   ;; rainbow and parenthesis
   (rainbow-delimiters-depth-1-face :foreground orange)
   (rainbow-delimiters-depth-2-face :foreground violet)
   (rainbow-delimiters-depth-3-face :foreground dark-cyan)
   (rainbow-delimiters-depth-4-face :foreground (doom-darken yellow 0.15))
   (rainbow-delimiters-unmatched-face: :foreground fg :background 'nil)
   (show-paren-match :foreground bg :background (doom-darken red 0.15))

   ;; vertico
   (vertico-current :foreground fg :background (doom-darken bg 0.1))

   ;; others
   (isearch :foreground fg :background (doom-lighten magenta 0.5))
   (selection :foreground bg-alt :background (doom-darken orange 0.15))
   (company-tooltip-common-selection :foreground bg-alt :background dark-blue)
   )


  ;; --- extra variables ---------------------
  ()
  )

;;; doom-everforest-light-theme.el ends here
