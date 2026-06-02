;;; doom-kanagawa-theme.el --- inspired by kanagawa.nvim -*- lexical-binding: t; no-byte-compile: t; -*-
;;
;; Author: drishal
;; Source: https://github.com/rebelot/kanagawa.nvim
;;
;;; Commentary:
;;
;; A doom-themes port of rebelot/kanagawa.nvim, bundling all three upstream
;; variants in a single theme:
;;
;;   - "wave"   : the default dark theme (Kanagawa)              [default]
;;   - "dragon" : a darker, muted dark theme (Kanagawa Dragon)
;;   - "lotus"  : the light theme (Kanagawa Lotus)
;;
;; Switch between them with the `doom-kanagawa-variant' variable, e.g.
;;
;;   (setq doom-kanagawa-variant "dragon")
;;   (load-theme 'doom-kanagawa t)
;;
;;; Code:

(require 'doom-themes)


;;
;;; Variables

(defgroup doom-kanagawa-theme nil
  "Options for the `doom-kanagawa' theme."
  :group 'doom-themes)

(defcustom doom-kanagawa-brighter-modeline nil
  "If non-nil, more vivid colors will be used to style the mode-line."
  :group 'doom-kanagawa-theme
  :type 'boolean)

(defcustom doom-kanagawa-brighter-comments nil
  "If non-nil, comments will be highlighted in more vivid colors."
  :group 'doom-kanagawa-theme
  :type 'boolean)

(defcustom doom-kanagawa-comment-bg doom-kanagawa-brighter-comments
  "If non-nil, comments will have a subtle, darker background.
Enhancing their legibility."
  :group 'doom-kanagawa-theme
  :type 'boolean)

(defcustom doom-kanagawa-padded-modeline doom-themes-padded-modeline
  "If non-nil, adds a 4px padding to the mode-line.
Can be an integer to determine the exact padding."
  :group 'doom-kanagawa-theme
  :type '(choice integer boolean))

(defcustom doom-kanagawa-variant nil
  "Color palette used for the kanagawa theme.
A choice of \"dragon\" or \"lotus\" can be used to switch flavour.
\"dragon\" is a darker, muted dark variant; \"lotus\" is the light
variant. All other values default to the \"wave\" dark theme."
  :group 'doom-kanagawa-theme
  :type 'string)

;;
;;; Theme definition

(def-doom-theme doom-kanagawa
  "A theme based on the kanagawa.nvim colorscheme (wave/dragon/lotus)."

  ;; name                                              default    256        16
  ;;;; Backgrounds and foregrounds (ui.*)
  ((_bg
    (cond ((equal doom-kanagawa-variant "dragon") '("#181616" "#1c1c1c" "black"))
          ((equal doom-kanagawa-variant "lotus")  '("#f2ecbc" "#ffffd7" "white"))
          (t                                      '("#1F1F28" "#1c1c1c" "black"))))
   (_bg-dim
    (cond ((equal doom-kanagawa-variant "dragon") '("#12120f" "#121212" "black"))
          ((equal doom-kanagawa-variant "lotus")  '("#dcd5ac" "#ffffaf" "brightwhite"))
          (t                                      '("#181820" "#121212" "black"))))
   (_bg-m3                              ; darkest bg (base0)
    (cond ((equal doom-kanagawa-variant "dragon") '("#0d0c0c" "#080808" "black"))
          ((equal doom-kanagawa-variant "lotus")  '("#d5cea3" "#ffffaf" "brightwhite"))
          (t                                      '("#16161D" "#080808" "black"))))
   (_bg-m2                              ; base1
    (cond ((equal doom-kanagawa-variant "dragon") '("#12120f" "#121212" "brightblack"))
          ((equal doom-kanagawa-variant "lotus")  '("#dcd5ac" "#ffffd7" "brightwhite"))
          (t                                      '("#181820" "#121212" "brightblack"))))
   (_bg-m1                              ; base2
    (cond ((equal doom-kanagawa-variant "dragon") '("#1D1C19" "#1c1c1c" "brightblack"))
          ((equal doom-kanagawa-variant "lotus")  '("#e5ddb0" "#ffffd7" "brightwhite"))
          (t                                      '("#1a1a22" "#1c1c1c" "brightblack"))))
   (_bg-p1                              ; lighter bg / gutter (base3)
    (cond ((equal doom-kanagawa-variant "dragon") '("#282727" "#262626" "brightblack"))
          ((equal doom-kanagawa-variant "lotus")  '("#a09cac" "#d7d7d7" "white"))
          (t                                      '("#2A2A37" "#262626" "brightblack"))))
   (_bg-p2                              ; lighter bg cursorline/selection (base4)
    (cond ((equal doom-kanagawa-variant "dragon") '("#393836" "#3a3a3a" "brightblack"))
          ((equal doom-kanagawa-variant "lotus")  '("#8a8980" "#b2b2b2" "white"))
          (t                                      '("#363646" "#3a3a3a" "brightblack"))))
   (_base5                             ; nontext / sumiInk6 (base5)
    (cond ((equal doom-kanagawa-variant "dragon") '("#625e5a" "#585858" "brightblack"))
          ((equal doom-kanagawa-variant "lotus")  '("#716e61" "#8a8a8a" "white"))
          (t                                      '("#54546D" "#585858" "brightblack"))))
   (_fg-dim                            ; oldWhite / lotusInk2 (base7)
    (cond ((equal doom-kanagawa-variant "dragon") '("#C8C093" "#bcbcbc" "white"))
          ((equal doom-kanagawa-variant "lotus")  '("#43436c" "#444466" "brightblack"))
          (t                                      '("#C8C093" "#bcbcbc" "white"))))
   (_fg                                ; fujiWhite / dragonWhite / lotusInk1 (base8)
    (cond ((equal doom-kanagawa-variant "dragon") '("#c5c9c5" "#c6c6c6" "brightwhite"))
          ((equal doom-kanagawa-variant "lotus")  '("#545464" "#303030" "black"))
          (t                                      '("#DCD7BA" "#dcdcdc" "brightwhite"))))

   ;;;; UI accents
   (_special                          ; springViolet1 / dragonGray3 / lotusViolet2
    (cond ((equal doom-kanagawa-variant "dragon") '("#7a8382" "#878787" "brightblack"))
          ((equal doom-kanagawa-variant "lotus")  '("#766b90" "#8787af" "brightblack"))
          (t                                      '("#938AA9" "#8787af" "brightblack"))))
   (_visual                           ; bg_visual (region/selection)
    (cond ((equal doom-kanagawa-variant "dragon") '("#223249" "#303030" "brightblack"))
          ((equal doom-kanagawa-variant "lotus")  '("#c9cbd1" "#d7d7d7" "white"))
          (t                                      '("#223249" "#303030" "brightblack"))))
   (_search                           ; bg_search
    (cond ((equal doom-kanagawa-variant "dragon") '("#2D4F67" "#005f87" "blue"))
          ((equal doom-kanagawa-variant "lotus")  '("#b5cbd2" "#afd7d7" "cyan"))
          (t                                      '("#2D4F67" "#005f87" "blue"))))

   ;;;; Syntax / accent colors (syn.*)
   (_comment                          ; fujiGray / dragonAsh / lotusGray3 (base6)
    (cond ((equal doom-kanagawa-variant "dragon") '("#737c73" "#6c6c6c" "brightblack"))
          ((equal doom-kanagawa-variant "lotus")  '("#8a8980" "#8a8a8a" "brightblack"))
          (t                                      '("#727169" "#6c6c6c" "brightblack"))))
   (_red                              ; waveRed / dragonRed / lotusRed
    (cond ((equal doom-kanagawa-variant "dragon") '("#c4746e" "#ff6655" "red"))
          ((equal doom-kanagawa-variant "lotus")  '("#c84053" "#ff6655" "red"))
          (t                                      '("#E46876" "#ff6655" "red"))))
   (_orange                           ; surimiOrange / dragonOrange / lotusOrange
    (cond ((equal doom-kanagawa-variant "dragon") '("#b6927b" "#dd8844" "brightred"))
          ((equal doom-kanagawa-variant "lotus")  '("#cc6d00" "#dd8844" "brightred"))
          (t                                      '("#FFA066" "#dd8844" "brightred"))))
   (_green                            ; springGreen / dragonGreen2 / lotusGreen
    (cond ((equal doom-kanagawa-variant "dragon") '("#8a9a7b" "#99bb66" "green"))
          ((equal doom-kanagawa-variant "lotus")  '("#6f894e" "#99bb66" "green"))
          (t                                      '("#98BB6C" "#99bb66" "green"))))
   (_teal                             ; waveAqua2 / dragonAqua / lotusAqua
    (cond ((equal doom-kanagawa-variant "dragon") '("#8ea4a2" "#44b9b1" "brightgreen"))
          ((equal doom-kanagawa-variant "lotus")  '("#597b75" "#44b9b1" "brightgreen"))
          (t                                      '("#7AA89F" "#44b9b1" "brightgreen"))))
   (_yellow                           ; carpYellow / dragonYellow / lotusYellow
    (cond ((equal doom-kanagawa-variant "dragon") '("#c4b28a" "#ecbe7b" "yellow"))
          ((equal doom-kanagawa-variant "lotus")  '("#77713f" "#ecbe7b" "yellow"))
          (t                                      '("#E6C384" "#ecbe7b" "yellow"))))
   (_blue                             ; crystalBlue / dragonBlue2 / lotusBlue4
    (cond ((equal doom-kanagawa-variant "dragon") '("#8ba4b0" "#51afef" "blue"))
          ((equal doom-kanagawa-variant "lotus")  '("#4d699b" "#51afef" "blue"))
          (t                                      '("#7E9CD8" "#51afef" "blue"))))
   (_dark-blue                        ; dragonBlue / lotusBlue5
    (cond ((equal doom-kanagawa-variant "dragon") '("#658594" "#2257a0" "blue"))
          ((equal doom-kanagawa-variant "lotus")  '("#5d57a3" "#2257a0" "blue"))
          (t                                      '("#658594" "#2257a0" "blue"))))
   (_magenta                          ; sakuraPink / dragonPink / lotusPink
    (cond ((equal doom-kanagawa-variant "dragon") '("#a292a3" "#c678dd" "brightmagenta"))
          ((equal doom-kanagawa-variant "lotus")  '("#b35b79" "#c678dd" "brightmagenta"))
          (t                                      '("#D27E99" "#c678dd" "brightmagenta"))))
   (_violet                           ; oniViolet / dragonViolet / lotusViolet4
    (cond ((equal doom-kanagawa-variant "dragon") '("#8992a7" "#a9a1e1" "magenta"))
          ((equal doom-kanagawa-variant "lotus")  '("#624c83" "#a9a1e1" "magenta"))
          (t                                      '("#957FB8" "#a9a1e1" "magenta"))))
   (_cyan                             ; springBlue / dragonTeal / lotusTeal1
    (cond ((equal doom-kanagawa-variant "dragon") '("#949fb5" "#46d9ff" "brightcyan"))
          ((equal doom-kanagawa-variant "lotus")  '("#4e8ca2" "#46d9ff" "brightcyan"))
          (t                                      '("#7FB4CA" "#46d9ff" "brightcyan"))))
   (_dark-cyan                        ; waveAqua1 / dragonAqua / lotusTeal3
    (cond ((equal doom-kanagawa-variant "dragon") '("#8ea4a2" "#5699af" "cyan"))
          ((equal doom-kanagawa-variant "lotus")  '("#5a7785" "#5699af" "cyan"))
          (t                                      '("#6A9589" "#5699af" "cyan"))))

   ;;;; Syntax roles that don't map onto a primary accent
   (_operator                         ; boatYellow2 / dragonRed / lotusYellow2
    (cond ((equal doom-kanagawa-variant "dragon") '("#c4746e" "#dfaf87" "yellow"))
          ((equal doom-kanagawa-variant "lotus")  '("#836f4a" "#dfaf87" "yellow"))
          (t                                      '("#C0A36E" "#dfaf87" "yellow"))))
   (_parameter                        ; oniViolet2 / dragonGray / lotusBlue5
    (cond ((equal doom-kanagawa-variant "dragon") '("#a6a69c" "#bcbcbc" "white"))
          ((equal doom-kanagawa-variant "lotus")  '("#5d57a3" "#5f5fd7" "blue"))
          (t                                      '("#b8b4d0" "#d7d7ff" "white"))))
   (_preproc                          ; waveRed / dragonRed / lotusRed
    (cond ((equal doom-kanagawa-variant "dragon") '("#c4746e" "#ff6655" "red"))
          ((equal doom-kanagawa-variant "lotus")  '("#c84053" "#ff6655" "red"))
          (t                                      '("#E46876" "#ff6655" "red"))))
   (_punct                            ; springViolet2 / dragonGray2 / lotusTeal1
    (cond ((equal doom-kanagawa-variant "dragon") '("#9e9b93" "#bcbcbc" "white"))
          ((equal doom-kanagawa-variant "lotus")  '("#4e8ca2" "#afafd7" "cyan"))
          (t                                      '("#9CABCA" "#afafd7" "white"))))
   (_special1                         ; springBlue / dragonTeal / lotusTeal2
    (cond ((equal doom-kanagawa-variant "dragon") '("#949fb5" "#5fafd7" "cyan"))
          ((equal doom-kanagawa-variant "lotus")  '("#6693bf" "#5fafd7" "cyan"))
          (t                                      '("#7FB4CA" "#5fafd7" "cyan"))))

   ;;;; Diagnostics (diag.*)
   (_error                            ; samuraiRed / lotusRed3
    (cond ((equal doom-kanagawa-variant "lotus")  '("#e82424" "#ff0000" "red"))
          (t                                      '("#E82424" "#ff0000" "red"))))
   (_warning                          ; roninYellow / lotusOrange2
    (cond ((equal doom-kanagawa-variant "lotus")  '("#e98a00" "#ffaf00" "brightyellow"))
          (t                                      '("#FF9E3B" "#ffaf00" "brightyellow"))))

   ;;;; VCS (vcs.*)
   (_vcs-added                        ; autumnGreen / lotusGreen2
    (cond ((equal doom-kanagawa-variant "lotus")  '("#6e915f" "#5f8700" "green"))
          (t                                      '("#76946A" "#5f8700" "green"))))
   (_vcs-removed                      ; autumnRed / lotusRed2
    (cond ((equal doom-kanagawa-variant "lotus")  '("#d7474b" "#ff0000" "red"))
          (t                                      '("#C34043" "#ff0000" "red"))))
   (_vcs-changed                      ; autumnYellow / lotusYellow3
    (cond ((equal doom-kanagawa-variant "lotus")  '("#de9800" "#dfaf00" "yellow"))
          (t                                      '("#DCA561" "#dfaf00" "yellow"))))

   ;;
   ;;; doom-themes universal palette

   (bg         _bg)
   (fg         _fg)

   ;; Off-color variants of bg/fg, used primarily for `solaire-mode'.
   (bg-alt     _bg-dim)
   (fg-alt     _fg-dim)

   ;; A spectrum from a starker bg (base0) to a starker fg (base8).
   (base0      _bg-m3)
   (base1      _bg-m2)
   (base2      _bg-m1)
   (base3      _bg-p1)
   (base4      _bg-p2)
   (base5      _base5)
   (base6      _comment)
   (base7      _fg-dim)
   (base8      _fg)

   (grey       base4)
   (red        _red)
   (orange     _orange)
   (green      _green)
   (teal       _teal)
   (yellow     _yellow)
   (blue       _blue)
   (dark-blue  _dark-blue)
   (magenta    _magenta)
   (violet     _violet)
   (cyan       _cyan)
   (dark-cyan  _dark-cyan)

   ;; These are the "universal syntax classes" that doom-themes establishes.
   ;; These *must* be included in every doom theme.
   (highlight      _blue)
   (vertical-bar   _bg-m3)
   (selection      _visual)
   (builtin        _orange)
   (comments       (if doom-kanagawa-brighter-comments _special1 _comment))
   (doc-comments   (if doom-kanagawa-brighter-comments _teal (doom-lighten _comment 0.1)))
   (constants      _orange)
   (functions      _blue)
   (keywords       _violet)
   (methods        _blue)
   (operators      _operator)
   (type           _teal)
   (strings        _green)
   (variables      _fg)
   (numbers        _magenta)
   (region         _visual)
   (error          _error)
   (warning        _warning)
   (success        _green)
   (vc-modified    _vcs-changed)
   (vc-added       _vcs-added)
   (vc-deleted     _vcs-removed)

   ;; These are extra color variables used only in this theme.
   (modeline-fg              fg)
   (modeline-fg-alt          base5)
   (modeline-bg              (if doom-kanagawa-brighter-modeline
                                 _search
                               (doom-darken bg-alt 0.05)))
   (modeline-bg-alt          (if doom-kanagawa-brighter-modeline
                                 _search
                               `(,(doom-darken (car bg-alt) 0.1) ,@(cdr bg))))
   (modeline-bg-inactive     `(,(car bg-alt) ,@(cdr base1)))
   (modeline-bg-inactive-alt `(,(doom-darken (car bg-alt) 0.05) ,@(cdr bg)))

   (-modeline-pad
    (when doom-kanagawa-padded-modeline
      (if (integerp doom-kanagawa-padded-modeline) doom-kanagawa-padded-modeline 4))))


  ;;;; Base theme face overrides
  (((line-number &override) :foreground _base5)
   ((line-number-current-line &override) :foreground fg :weight 'bold)
   ((font-lock-comment-face &override)
    :background (if doom-kanagawa-comment-bg (doom-lighten bg 0.05))
    :slant 'italic)
   (font-lock-keyword-face :foreground keywords :weight 'normal)
   (font-lock-preprocessor-face :foreground _preproc)
   (font-lock-variable-name-face :foreground variables)
   ;; Match kanagawa.nvim: attribute keys (@property -> @variable.member ->
   ;; identifier = carpYellow) are yellow, not the doom-themes-base default
   ;; that blends from `keywords' (violet).
   (font-lock-property-name-face :foreground yellow)
   (font-lock-property-use-face  :inherit 'font-lock-property-name-face)
   (font-lock-constant-face :foreground _orange)
   ((font-lock-function-name-face &override) :foreground functions)
   ;; Match kanagawa.nvim: function/method CALLS use the full `fun' color, not
   ;; the doom-themes-base default that blends 70% toward fg (washed-out blue).
   ;; Keep the inherited italic slant.
   ((font-lock-function-call-face &override) :foreground functions)
   ;; Match kanagawa.nvim: delimiters/brackets/`::` are punct (springViolet2),
   ;; not the doom-themes-base default that blends from `operators' (yellow).
   ;; bracket/delimiter/misc-punctuation inherit this face.
   (font-lock-punctuation-face :foreground _punct)
   ((font-lock-type-face &override) :foreground type)
   (hl-line :background _bg-p2)
   (cursor :background (if (equal doom-kanagawa-variant "lotus") _violet _orange))
   (fringe :background bg :foreground _base5)

   (mode-line
    :background modeline-bg :foreground modeline-fg
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg)))
   (mode-line-inactive
    :background modeline-bg-inactive :foreground modeline-fg-alt
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-inactive)))
   (mode-line-emphasis :foreground (if doom-kanagawa-brighter-modeline base8 highlight))

   ;;;; centaur-tabs
   (centaur-tabs-selected :background bg :foreground fg)
   (centaur-tabs-unselected :background bg-alt :foreground fg-alt)
   (centaur-tabs-selected-modified :background bg :foreground _orange)
   (centaur-tabs-unselected-modified :background bg-alt :foreground _orange)
   (centaur-tabs-active-bar-face :background highlight)
   (centaur-tabs-modified-marker-selected :background bg :foreground highlight)
   (centaur-tabs-modified-marker-unselected :background bg-alt :foreground highlight)

   ;;;; css-mode <built-in> / scss-mode
   (css-proprietary-property :foreground _orange)
   (css-property             :foreground _green)
   (css-selector             :foreground _blue)

   ;;;; doom-modeline
   (doom-modeline-bar :background (if doom-kanagawa-brighter-modeline modeline-bg highlight))
   (doom-modeline-buffer-file :inherit 'mode-line-buffer-id :weight 'bold)
   (doom-modeline-buffer-path :inherit 'mode-line-emphasis :weight 'bold)
   (doom-modeline-buffer-project-root :foreground _green :weight 'bold)
   (doom-modeline-buffer-modified :foreground _orange)

   ;;;; ivy
   (ivy-current-match :background _visual :distant-foreground base0 :weight 'normal)
   (ivy-minibuffer-match-face-1 :foreground _comment :background nil :weight 'light)
   (ivy-minibuffer-match-face-2 :foreground _blue :weight 'bold :underline t)

   ;;;; LaTeX-mode
   (font-latex-math-face :foreground _green)

   ;;;; markdown-mode
   (markdown-markup-face :foreground base5)
   (markdown-header-face :inherit 'bold :foreground _red)
   (markdown-blockquote-face :inherit 'italic :foreground _comment)
   ((markdown-code-face &override) :background (doom-lighten base3 0.05))
   (markdown-list-face :foreground _violet)
   (markdown-url-face :foreground _cyan)
   (markdown-link-face :foreground _blue :underline t)

   ;;;; rjsx-mode
   (rjsx-tag :foreground _red)
   (rjsx-attr :foreground _orange :slant 'italic :weight 'medium)

   ;;;; solaire-mode
   (solaire-hl-line-face :background base2)
   (solaire-mode-line-face
    :inherit 'mode-line
    :background modeline-bg-alt
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-alt)))
   (solaire-mode-line-inactive-face
    :inherit 'mode-line-inactive
    :background modeline-bg-inactive-alt
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-inactive-alt)))
   (solaire-region-face :background region)

   ;;;; company
   (company-tooltip-selection :background _visual)
   (company-tooltip :background base2 :foreground fg)
   (company-tooltip-common :foreground _blue :weight 'bold)
   (company-scrollbar-bg :background base2)
   (company-scrollbar-fg :background _search)

   ;;;; tab-bar-mode
   (tab-bar :background bg-alt :foreground fg-alt)
   (tab-bar-tab :background bg :foreground fg :weight 'bold)
   (tab-bar-tab-inactive :background bg-alt :foreground fg-alt)

   ;;;; org <built-in>
   (org-agenda-date :foreground cyan)
   (org-agenda-dimmed-todo-face :foreground comments)
   (org-agenda-done :foreground base4)
   (org-agenda-structure :foreground violet)
   ((org-block &override) :background (doom-darken base1 0.1) :foreground violet)
   ((org-block-begin-line &override) :background (doom-darken base1 0.1))
   ((org-code &override) :foreground yellow)
   (org-column :background base1)
   (org-column-title :background base1 :bold t :underline t)
   (org-date :foreground cyan)
   ((org-document-info &override) :foreground blue)
   ((org-document-info-keyword &override) :foreground comments)
   (org-done :foreground green :background base2 :weight 'bold)
   (org-footnote :foreground blue)
   (org-headline-base :foreground comments :strike-through t :bold nil)
   (org-headline-done :foreground base4 :strike-through nil)
   ((org-link &override) :foreground orange)
   (org-priority :foreground cyan)
   ((org-quote &override) :background (doom-darken base1 0.1))
   (org-scheduled :foreground green)
   (org-scheduled-previously :foreground yellow)
   (org-scheduled-today :foreground orange)
   (org-sexp-date :foreground base4)
   ((org-special-keyword &override) :foreground yellow)
   (org-table :foreground violet)
   ((org-tag &override) :foreground (doom-lighten orange 0.3))
   (org-todo :foreground orange :bold 'inherit :background (doom-darken base1 0.02))
   (org-upcoming-deadline :foreground yellow)
   (org-warning :foreground magenta)

   ;;;; web-mode
   (web-mode-builtin-face :foreground orange)
   (web-mode-css-selector-face :foreground green)
   (web-mode-html-attr-name-face :foreground orange)
   (web-mode-html-tag-bracket-face :inherit 'default)
   (web-mode-html-tag-face :foreground magenta :weight 'bold)
   (web-mode-preprocessor-face :foreground orange)

   ;;;; dired
   (dired-directory :foreground _blue)
   (dired-marked :foreground yellow)
   (dired-symlink :foreground cyan)
   (dired-header :foreground cyan :weight 'bold))


  ;;;; Base theme variable overrides
  ())

;;; doom-kanagawa-theme.el ends here
