;;; doom-gruvbox-material.el --- inspired by Gruvbox material -*- lexical-binding: t; no-byte-compile: t; -*-
;;; https://github.com/sainnhe/gruvbox-material/blob/master/autoload/gruvbox_material.vim
(require 'doom-themes)

;;
(defgroup doom-gruvbox-material-theme nil
  "Options for doom-themes"
  :group 'doom-themes)

(defcustom doom-gruvbox-material-brighter-modeline nil
  "If non-nil, more vivid colors will be used to style the mode-line."
  :group 'doom-gruvbox-material-theme
  :type 'boolean)

(defcustom doom-gruvbox-material-brighter-comments nil
  "If non-nil, comments will be highlighted in more vivid colors."
  :group 'doom-gruvbox-material-theme
  :type 'boolean)

(defcustom doom-gruvbox-material-comment-bg doom-gruvbox-material-brighter-comments
  "If non-nil, comments will have a subtle, darker background. Enhancing their
legibility."
  :group 'doom-gruvbox-material-theme
  :type 'boolean)

(defcustom doom-gruvbox-material-padded-modeline doom-themes-padded-modeline
  "If non-nil, adds a 4px padding to the mode-line. Can be an integer to
determine the exact padding."
  :group 'doom-gruvbox-material-theme
  :type '(choice integer boolean))

(defcustom doom-gruvbox-material-background "medium"
  "Choose between \"soft\", \"medium\" and \"hard\" background contrast.
Defaults to \"medium\", matching upstream gruvbox-material."
  :group 'doom-gruvbox-material-theme
  :type 'string)

(defcustom doom-gruvbox-material-palette nil
  "Choose between \"material\", \"mix\" and \"original\" color palette.
Defaults to \"material\""
  :group 'doom-gruvbox-material-theme
  :type 'string)

(defcustom doom-gruvbox-material-dired-height 1.15
  "Font height for dired buffers"
  :group 'doom-gruvbox-material-theme
  :type 'float)
;; colors from
;; https://github.com/sainnhe/gruvbox-material-vscode/tree/master/src/palette
(cond
 ((equal doom-gruvbox-material-background "hard")
  (setq gm/bg           "#1d2021"       ;; bg0 (hard)
        gm/bg-alt       "#282828"       ;; bg1
        gm/base0        "#141617"       ;; bg_dim
        gm/base1        "#1d2021"       ;; bg0
        gm/base2        "#282828"       ;; bg1
        gm/base3        "#3c3836"       ;; bg3
        gm/base4        "#504945"       ;; bg5
        gm/base5        "#665c54"       ;; Doom base ramp (not an upstream bg role)
        gm/base6        "#7c6f64"       ;; grey0
        gm/base7        "#928374"       ;; grey1
        gm/base8        "#a89984"))     ;; grey2
 ((equal doom-gruvbox-material-background "medium")
  (setq gm/bg           "#282828"       ;; bg0 (medium)
        gm/bg-alt       "#32302f"       ;; bg1
        gm/base0        "#1b1b1b"       ;; bg_dim
        gm/base1        "#282828"       ;; bg0
        gm/base2        "#32302f"       ;; bg1
        gm/base3        "#45403d"       ;; bg3
        gm/base4        "#5a524c"       ;; bg5
        gm/base5        "#665c54"       ;; Doom base ramp (not an upstream bg role)
        gm/base6        "#7c6f64"       ;; grey0
        gm/base7        "#928374"       ;; grey1
        gm/base8        "#a89984"))     ;; grey2
 (t
  (setq gm/bg           "#32302f"       ;; bg0 (soft)
        gm/bg-alt       "#3c3836"       ;; bg1
        gm/base0        "#252423"       ;; bg_dim
        gm/base1        "#32302f"       ;; bg0
        gm/base2        "#3c3836"       ;; bg1
        gm/base3        "#504945"       ;; bg3
        gm/base4        "#665c54"       ;; bg5
        gm/base5        "#7c6f64"       ;; grey0
        gm/base6        "#928374"       ;; grey1
        gm/base7        "#928374"       ;; grey1
        gm/base8        "#a89984")))    ;; grey2

(cond
 ((equal doom-gruvbox-material-palette "original")
  (setq gm/fg           "#ebdbb2"       ;; fg
        gm/fg-alt       "#ebdbb2"       ;; fg1
        gm/red          "#fb4934"
        gm/dark-red     "#fb4934"       ;; upstream has no dimRed in current palette
        gm/orange       "#fe8019"
        gm/dark-orange  "#fe8019"       ;; upstream has no dimOrange in current palette
        gm/green        "#b8bb26"
        gm/dark-green   "#b8bb26"       ;; upstream has no dimGreen in current palette
        gm/teal         "#8ec07c"       ;; aqua
        gm/dark-teal    "#8ec07c"       ;; upstream has no dimAqua in current palette
        gm/yellow       "#fabd2f"
        gm/dark-yellow  "#fabd2f"       ;; upstream has no dimYellow in current palette
        gm/blue         "#83a598"
        gm/dark-blue    "#83a598"       ;; upstream has no dimBlue in current palette
        gm/magenta      "#d3869b"       ;; purple
        gm/violet       "#d3869b"       ;; upstream has no dimPurple in current palette
        gm/cyan         "#8ec07c"       ;; aqua
        gm/dark-cyan    "#8ec07c"))     ;; upstream has no dimAqua in current palette
 ((equal doom-gruvbox-material-palette "mix")
  (setq gm/fg           "#e2cca9"       ;; fg
        gm/fg-alt       "#e2cca9"       ;; fg1
        gm/red          "#f2594b"
        gm/dark-red     "#f2594b"       ;; upstream has no dimRed in current palette
        gm/orange       "#f28534"
        gm/dark-orange  "#f28534"       ;; upstream has no dimOrange in current palette
        gm/green        "#b0b846"
        gm/dark-green   "#b0b846"       ;; upstream has no dimGreen in current palette
        gm/teal         "#8bba7f"       ;; aqua
        gm/dark-teal    "#8bba7f"       ;; upstream has no dimAqua in current palette
        gm/yellow       "#e9b143"
        gm/dark-yellow  "#e9b143"       ;; upstream has no dimYellow in current palette
        gm/blue         "#80aa9e"
        gm/dark-blue    "#80aa9e"       ;; upstream has no dimBlue in current palette
        gm/magenta      "#d3869b"       ;; purple
        gm/violet       "#d3869b"       ;; upstream has no dimPurple in current palette
        gm/cyan         "#8bba7f"       ;; aqua
        gm/dark-cyan    "#8bba7f"))     ;; upstream has no dimAqua in current palette
 (t
  (setq gm/fg           "#d4be98"       ;; fg
        gm/fg-alt       "#ddc7a1"       ;; fg1
        gm/red          "#ea6962"
        gm/dark-red     "#ea6962"       ;; upstream has no dimRed in current palette
        gm/orange       "#e78a4e"
        gm/dark-orange  "#e78a4e"       ;; upstream has no dimOrange in current palette
        gm/green        "#a9b665"
        gm/dark-green   "#a9b665"       ;; upstream has no dimGreen in current palette
        gm/teal         "#89b482"       ;; aqua
        gm/dark-teal    "#89b482"       ;; upstream has no dimAqua in current palette
        gm/yellow       "#d8a657"
        gm/dark-yellow  "#d8a657"       ;; upstream has no dimYellow in current palette
        gm/blue         "#7daea3"
        gm/dark-blue    "#7daea3"       ;; upstream has no dimBlue in current palette
        gm/magenta      "#d3869b"       ;; purple
        gm/violet       "#d3869b"       ;; upstream has no dimPurple in current palette
        gm/cyan         "#89b482"       ;; aqua
        gm/dark-cyan    "#89b482")))    ;; upstream has no dimAqua in current palette

;; Gruvbox Material dark greys are global across hard/medium/soft backgrounds.
;; Keep them explicit instead of deriving semantic greys from Doom's baseN ramp.
(setq gm/grey0 "#7c6f64"
      gm/grey1 "#928374"
      gm/grey2 "#a89984")

(def-doom-theme doom-gruvbox-material
  "A dark theme inspired by gruvbox material"
  ;; name       default                 256       16
  ((bg          `(,gm/bg                "#282828"       nil            ))
   (bg-alt      `(,gm/bg-alt            "#303030"       nil            ))
   (base0       `(,gm/base0             "black"   "black"        ))
   (base1       `(,gm/base1             "#121212" "brightblack"  ))
   (base2       `(,gm/base2             "#2e2e2e" "brightblack"  ))
   (base3       `(,gm/base3             "#262626" "brightblack"  ))
   (base4       `(,gm/base4             "#3f3f3f" "brightblack"  ))
   (base5       `(,gm/base5             "#585858" "brightblack"  ))
   (base6       `(,gm/base6             "#6b6b6b" "brightblack"  ))
   (base7       `(,gm/base7             "#979797" "brightblack"  ))
   (base8       `(,gm/base8             "#767676" "white"        ))
   (fg          `(,gm/fg                "#d7d7af" "brightwhite"  ))
   (fg-alt      `(,gm/fg-alt            "#b2b2b2" "white"        ))

   (grey0       `(,gm/grey0             "#6b6b6b" "brightblack"  ))
   (grey1       `(,gm/grey1             "#979797" "brightblack"  ))
   (grey2       `(,gm/grey2             "#a89984" "white"        ))
   (grey        grey1)
   (red         `(,gm/red               "#ea6962" "red"          ))
   (dark-red    `(,gm/dark-red          "#ea6962" "red"          ))
   (orange      `(,gm/orange            "#d7875f" "brightred"    ))
   (dark-orange `(,gm/dark-orange       "#d7875f" "brightred"    ))
   (green       `(,gm/green             "#afd700" "green"        ))
   (dark-green  `(,gm/dark-green        "#afd700" "green"        ))
   (teal        `(,gm/teal              "#87d7af" "brightgreen"  ))
   (dark-teal   `(,gm/dark-teal         "#87d7af" "brightgreen"  ))
   (yellow      `(,gm/yellow            "#d7d787" "yellow"       ))
   (dark-yellow `(,gm/dark-yellow       "#d7d787" "yellow"       ))
   (blue        `(,gm/blue              "#83a598" "brightblue"   ))
   (dark-blue   `(,gm/dark-blue         "#83a598" "blue"         ))
   (magenta     `(,gm/magenta           "#d3869b" "brightmagenta"))
   (violet      `(,gm/violet            "#d3869b" "magenta"      ))
   (cyan        `(,gm/cyan              "#87d7af" "brightcyan"   ))
   (dark-cyan   `(,gm/dark-cyan         "#87d7af" "cyan"         ))

   ;; face categories -- required for all themes
   ;; Mapping mirrors gruvbox-material.nvim's treesit scheme:
   ;; keywords=red, functions/calls/builtin=green, type=yellow, constants=aqua,
   ;; variables/params=fg, fields/properties=blue, operators=orange,
   ;; numbers=purple, comments=grey1, brackets=fg, delimiters=grey.
   (highlight       blue)
   (vertical-bar   (doom-darken base1 0.1))
   (selection       base3)
   (builtin         green) ;; @function.builtin/@constructor = GreenBold
   (comments        (if doom-gruvbox-material-brighter-comments grey2 grey))
   (doc-comments    grey)
   (constants      teal)
   (functions      green)
   (keywords       red)
   (methods        green)
   (operators      orange)
   (type           yellow)
   (strings        teal)              ;; TSString → Aqua (#89b482)
   (variables      fg) ;; @variable / @variable.parameter = Fg (treesit)
   (numbers        magenta)
   (region         base3) ;; Visual = bg3
   (error          red)
   (warning        yellow)
   (success        green)
   (vc-modified    orange)
   (vc-added       green)
   (vc-deleted     red)

   ;; custom categories
   (hidden     `(,(car bg) "black" "black"))
   (-modeline-bright doom-gruvbox-material-brighter-modeline)
   (-modeline-pad
    (when doom-gruvbox-material-padded-modeline
      (if (integerp doom-gruvbox-material-padded-modeline) doom-gruvbox-material-padded-modeline 4)))

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

   ((line-number &override) :foreground (doom-darken fg-alt 0.4))
   ((line-number-current-line &override) :foreground fg)

   (font-lock-comment-face
    :foreground comments
    :slant 'italic                                  ;; Comment → grey1 italic
    :background (if doom-gruvbox-material-comment-bg (doom-lighten bg 0.05)))
   (font-lock-doc-face
    :inherit 'font-lock-comment-face
    :foreground doc-comments
    :slant 'italic)                                 ;; SpecialComment → grey1 italic

   ;; Match gruvbox-material.nvim treesit groups (override doom-themes-base
   ;; defaults that derive these from keywords/operators or blend toward fg):
   ;; @function.call / @method.call = GreenBold (TSFunction → GreenBold).
   ((font-lock-function-call-face &override) :foreground functions :weight 'bold)
   ;; @function / @constructor = GreenBold
   ((font-lock-function-name-face &override) :foreground functions :weight 'bold)
   ;; @keyword / @conditional / @repeat = RedItalic (TSKeyword → RedItalic).
   ((font-lock-keyword-face &override) :foreground keywords :slant 'italic)
   ;; @type / @type.builtin = YellowItalic (TSType → YellowItalic).
   ((font-lock-type-face &override) :foreground type :slant 'italic)
   ;; @property / @field / @variable.member = blue (TSProperty/TSField → Blue).
   (font-lock-property-name-face :foreground blue)
   (font-lock-property-use-face  :inherit 'font-lock-property-name-face)
   ;; @punctuation.bracket = fg (Fg); brackets/misc inherit punctuation.
   (font-lock-punctuation-face :foreground fg)
   ;; @punctuation.delimiter = grey1 (Grey); override the punctuation inherit.
   (font-lock-delimiter-face :foreground grey)
   ;; @variable.builtin / @constant.builtin = PurpleItalic (TSVariableBuiltin/TSConstBuiltin).
   ;; builtin in doom maps to font-lock-builtin-face, but Neovim's TSFuncBuiltin = GreenBold
   ;; while TSVariableBuiltin = PurpleItalic. Override builtin to add bold (GreenBold).
   ((font-lock-builtin-face &override) :foreground builtin :weight 'bold)
   ;; @string.escape / @string.regex = Green (TSStringEscape/TSStringRegex → Green).
   ;; @namespace / @module = YellowItalic (TSNamespace → YellowItalic).
   ;; These are handled via tree-sitter faces below.

   ;; Built-in treesit/rust-ts-mode equivalents.  rust-ts-mode maps Rust modules
   ;; (`phnt`, `ffi`, `core`, `asm`) to `font-lock-constant-face`, while nvim
   ;; gruvbox-material maps `@module` to TSNamespace → YellowItalic.  Variables
   ;; stay Fg to match nvim's `@variable` / `@variable.parameter`.
   ((font-lock-variable-name-face &override) :foreground fg) ;; @variable → Fg
   ((font-lock-variable-use-face &override) :foreground fg)  ;; @variable → Fg
   ((font-lock-constant-face &override) :foreground yellow)  ;; rust-ts @module → Yellow
   ((font-lock-preprocessor-face &override) :foreground magenta) ;; PreProc/@attribute → Purple
   ((font-lock-string-face &override) :foreground teal)      ;; @string → Aqua
   ((font-lock-number-face &override) :foreground magenta)   ;; @number → Purple
   ((font-lock-operator-face &override) :foreground orange)  ;; @operator → Orange
   ((font-lock-bracket-face &override) :foreground fg)       ;; @punctuation.bracket → Fg
   ((font-lock-warning-face &override) :foreground warning :weight 'bold)

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
   (doom-modeline-buffer-project-root :foreground blue :weight 'bold)

   ;; ivy-mode
   (ivy-current-match :background blue :distant-foreground base0 :weight 'bold)
   ;; (ivy-current-match :foreground blue :background bg)
   (ivy-minibuffer-match-face-2 :foreground blue :background bg)

   ;; --- major-mode faces -------------------
   ;; column indicator
   (fill-column-indicator :foreground bg-alt :background bg-alt)

   ;; css-mode / scss-mode
   (css-proprietary-property :foreground orange)
   (css-property             :foreground green)
   (css-selector             :foreground blue)

   ;; dired
   (diredfl-compressed-file-name :height doom-gruvbox-material-dired-height
                    :foreground yellow)
   (diredfl-dir-heading :height doom-gruvbox-material-dired-height
                        :foreground teal)
   (diredfl-dir-name :height doom-gruvbox-material-dired-height
                     :foreground blue)
   (diredfl-deletion :height doom-gruvbox-material-dired-height
                     :foreground red :background (doom-darken red 0.55))
   (diredfl-deletion-file-name :foreground red
                               :background (doom-darken red 0.55))
   (diredfl-file-name :height doom-gruvbox-material-dired-height
                      :foreground fg)
   (dired-flagged :height doom-gruvbox-material-dired-height
                    :foreground red :background (doom-darken red 0.55))
   (diredfl-symlink :height doom-gruvbox-material-dired-height
                    :foreground magenta)

   ;; eshell
   (+eshell-prompt-git-branch :foreground cyan)

   ;; evil
   (evil-ex-lazy-highlight :foreground bg :background yellow)
   (evil-snipe-first-match-face :foreground bg :background orange)

   ;; LaTeX-mode
   (font-latex-math-face :foreground dark-green)
   (font-latex-script-char-face :foreground dark-blue)

   ;; lsp
   (lsp-face-highlight-read :foreground fg-alt
                            :background (doom-darken blue 0.6))
   (lsp-face-highlight-textual :foreground fg-alt
                               :background (doom-darken blue 0.6))
   (lsp-face-highlight-write :foreground fg-alt
                             :background (doom-darken blue 0.6))
   (lsp-lsp-flycheck-info-unnecessary-face
    :foreground (doom-lighten dark-yellow 0.12))

   ;; magit
   (magit-section-heading :foreground blue :weight 'bold)

   ;; markdown-mode
   (markdown-markup-face :foreground base5)
   (markdown-header-face :inherit 'bold :foreground blue)
   ((markdown-code-face &override) :background (doom-lighten base3 0.05))

   ;; org-mode
   (org-hide :foreground hidden)
   (solaire-org-hide-face :foreground hidden)
   (org-document-info :foreground blue)
   (org-document-info-keyword :foreground dark-blue)
   (org-document-title :foreground blue)
   (org-block-begin-line :foreground dark-cyan
                         :background bg-alt)
   (org-block-end-line :foreground dark-cyan
                         :background bg-alt)
   (org-block :foreground fg :background bg-alt)
   (org-meta-line :foreground dark-cyan)
   (org-drawer :foreground dark-yellow)
   (org-level-1 :foreground magenta :weight 'semi-bold :height 1.4)
   (org-level-2 :foreground cyan :weight 'semi-bold :height 1.2)
   (org-level-3 :foreground green :weight 'semi-bold :height 1.1)
   (org-level-4 :foreground yellow :weight 'semi-bold)
   (org-level-5 :foreground violet :weight 'semi-bold)
   (org-level-6 :foreground dark-cyan :weight 'semi-bold)
   (org-level-7 :foreground dark-green :weight 'semi-bold)
   (org-level-8 :foreground dark-yellow :weight 'semi-bold)

   ;; rainbow and parenthesis
   (rainbow-delimiters-depth-1-face :foreground dark-orange)
   (rainbow-delimiters-depth-2-face :foreground violet)
   (rainbow-delimiters-depth-3-face :foreground dark-cyan)
   (rainbow-delimiters-depth-4-face :foreground dark-yellow)
   (rainbow-delimiters-depth-5-face :foreground green)
   (rainbow-delimiters-depth-6-face :foreground blue)
   (rainbow-delimiters-depth-7-face :foreground magenta)
   (rainbow-delimiters-unmatched-face :foreground red :background nil)
   (show-paren-match :background base3)                       ;; MatchParen → bg4/bg3

   ;; tree sitter — match gruvbox-material.nvim TS* / @* groups exactly
   (tree-sitter-hl-face:method.call :foreground green :weight 'bold)   ;; TSMethodCall → GreenBold
   (tree-sitter-hl-face:function.call :foreground green :weight 'bold) ;; TSFunctionCall → GreenBold
   (tree-sitter-hl-face:function :foreground green :weight 'bold)      ;; TSFunction → GreenBold
   (tree-sitter-hl-face:method :foreground green :weight 'bold)        ;; TSMethod → GreenBold
   (tree-sitter-hl-face:constructor :foreground green :weight 'bold)   ;; TSConstructor → GreenBold
   (tree-sitter-hl-face:function.builtin :foreground green :weight 'bold) ;; TSFuncBuiltin → GreenBold
   (tree-sitter-hl-face:keyword :foreground red :slant 'italic)        ;; TSKeyword → RedItalic
   (tree-sitter-hl-face:conditional :foreground red :slant 'italic)    ;; TSConditional → RedItalic
   (tree-sitter-hl-face:repeat :foreground red :slant 'italic)         ;; TSRepeat → RedItalic
   (tree-sitter-hl-face:type :foreground yellow :slant 'italic)        ;; TSType → YellowItalic
   (tree-sitter-hl-face:type.builtin :foreground yellow :slant 'italic) ;; TSTypeBuiltin → YellowItalic
   (tree-sitter-hl-face:type.definition :foreground yellow :slant 'italic) ;; TSTypeDefinition → YellowItalic
   (tree-sitter-hl-face:variable.builtin :foreground magenta :slant 'italic) ;; TSVariableBuiltin → PurpleItalic
   (tree-sitter-hl-face:constant.builtin :foreground magenta :slant 'italic) ;; TSConstBuiltin → PurpleItalic
   (tree-sitter-hl-face:constant.macro :foreground magenta :slant 'italic)  ;; TSConstMacro → PurpleItalic
   (tree-sitter-hl-face:number :foreground magenta)                    ;; TSNumber → Purple
   (tree-sitter-hl-face:float :foreground magenta)                     ;; TSFloat → Purple
   (tree-sitter-hl-face:boolean :foreground magenta :slant 'italic)    ;; TSBoolean → PurpleItalic
   (tree-sitter-hl-face:string :foreground teal)                       ;; TSString → Aqua
   (tree-sitter-hl-face:string.escape :foreground green)               ;; TSStringEscape → Green
   (tree-sitter-hl-face:string.regex :foreground green)                ;; TSStringRegex → Green
   (tree-sitter-hl-face:field :foreground blue)                        ;; TSField → Blue
   (tree-sitter-hl-face:property :foreground blue)                     ;; TSProperty → Blue
   (tree-sitter-hl-face:parameter :foreground fg)                      ;; TSParameter → Fg
   (tree-sitter-hl-face:variable :foreground fg)                       ;; TSVariable → Fg
   (tree-sitter-hl-face:namespace :foreground yellow :slant 'italic)   ;; TSNamespace → YellowItalic
   (tree-sitter-hl-face:operator :foreground orange)                   ;; TSOperator → Orange
   (tree-sitter-hl-face:keyword.operator :foreground orange)           ;; TSKeywordOperator → Orange
   (tree-sitter-hl-face:punctuation.bracket :foreground fg)            ;; TSPunctBracket → Fg
   (tree-sitter-hl-face:punctuation.delimiter :foreground grey)        ;; TSPunctDelimiter → Grey
   (tree-sitter-hl-face:tag :foreground orange)                        ;; TSTag → Orange
   (tree-sitter-hl-face:label :foreground orange)                      ;; TSLabel → Orange
   ;; --- missing captures matched to upstream nvim-treesitter ---
   ;; @attribute → Purple  (fixes #![...] Rust attr blocks being green)
   (tree-sitter-hl-face:attribute :foreground magenta)                 ;; @attribute → Purple
   ;; @keyword.directive/@keyword.directive.define → Purple  (sets the #! token)
   (tree-sitter-hl-face:preproc :foreground magenta)                   ;; @keyword.directive → Purple
   (tree-sitter-hl-face:define :foreground magenta)                    ;; @keyword.directive.define → Purple
   ;; @include → Red  (use, mod, extern crate)
   (tree-sitter-hl-face:include :foreground red)                       ;; @include → Red
   (tree-sitter-hl-face:keyword.import :foreground red)                ;; @keyword.import → Red
   ;; @keyword.function → RedItalic  (fn, async fn)
   (tree-sitter-hl-face:keyword.function :foreground red :slant 'italic) ;; @keyword.function → RedItalic
   ;; @keyword.return → Red
   (tree-sitter-hl-face:keyword.return :foreground red)                ;; @keyword.return → Red
   ;; @exception → RedItalic
   (tree-sitter-hl-face:exception :foreground red :slant 'italic)      ;; @exception → RedItalic
   ;; @function.macro → GreenBold  (macro_rules!, assert!, etc.)
   (tree-sitter-hl-face:function.macro :foreground green :weight 'bold) ;; @function.macro → GreenBold
   ;; @constant → Fg  (unset would fall through to (constants teal))
   (tree-sitter-hl-face:constant :foreground fg)                       ;; @constant → Fg
   ;; @storageclass / @storageclass.lifetime → Orange
   (tree-sitter-hl-face:storageclass :foreground orange)               ;; @storageclass → Orange
   (tree-sitter-hl-face:storageclass.lifetime :foreground orange)      ;; @storageclass.lifetime → Orange
   (tree-sitter-hl-face:keyword.storage :foreground orange)            ;; @keyword.storage → Orange
   ;; @type.qualifier → Orange  (const, mut in type positions)
   (tree-sitter-hl-face:type.qualifier :foreground orange)             ;; @type.qualifier → Orange
   ;; @punctuation.special → Blue  (::, =>, etc.)
   (tree-sitter-hl-face:punctuation.special :foreground blue)          ;; @punctuation.special → Blue
   ;; @annotation → Purple  (decorators, derives)
   (tree-sitter-hl-face:annotation :foreground magenta)                ;; @annotation → Purple
   ;; @character → Aqua  (char literals)
   (tree-sitter-hl-face:character :foreground teal)                    ;; @character → Aqua
   ;; @symbol → Fg
   (tree-sitter-hl-face:symbol :foreground fg)                         ;; @symbol → Fg
   ;; @variable.member → Blue; @variable.parameter → Fg
   (tree-sitter-hl-face:variable.member :foreground blue)              ;; @variable.member → Blue
   (tree-sitter-hl-face:variable.parameter :foreground fg)             ;; @variable.parameter → Fg
   ;; @tag.attribute / @tag.delimiter → Green  (HTML/JSX)
   (tree-sitter-hl-face:tag.attribute :foreground green)               ;; @tag.attribute → Green
   (tree-sitter-hl-face:tag.delimiter :foreground green)               ;; @tag.delimiter → Green
   ;; @comment → grey1 (handled by font-lock-comment-face, but explicit for ts)
   (tree-sitter-hl-face:comment :foreground grey)                      ;; @comment → Grey
   ;; @todo → blue bold (TODO/FIXME in comments)
   (tree-sitter-hl-face:todo :foreground blue :weight 'bold)           ;; @todo → BlueBold
   ;; @error → red (syntax errors)
   (tree-sitter-hl-face:error :foreground red)                         ;; @error → Red
   ;; @title → orange bold (markdown headings)
   (tree-sitter-hl-face:title :foreground orange :weight 'bold)        ;; @title → OrangeBold
   ;; @text → fg (plain text in markup)
   (tree-sitter-hl-face:text :foreground fg)                           ;; @text → Fg
   (tree-sitter-hl-face:text.literal :foreground green)                ;; @text.literal → TSLiteral → String
   (tree-sitter-hl-face:text.reference :foreground teal)               ;; @text.reference → Constant → Aqua
   (tree-sitter-hl-face:text.danger :foreground bg :background red :weight 'bold) ;; @text.danger → TSDanger
   (tree-sitter-hl-face:text.warning :foreground bg :background yellow :weight 'bold) ;; @text.warning → TSWarning
   (tree-sitter-hl-face:text.note :foreground bg :background green :weight 'bold) ;; @text.note → TSNote
   (tree-sitter-hl-face:text.uri :foreground blue :underline t)        ;; @text.uri → TSURI
   (tree-sitter-hl-face:markup.raw :foreground green)                  ;; @markup.raw → TSLiteral
   (tree-sitter-hl-face:markup.link :foreground teal)                  ;; @markup.link → TSTextReference
   (tree-sitter-hl-face:markup.link.url :foreground blue :underline t) ;; @markup.link.url → TSURI
   (tree-sitter-hl-face:markup.quote :foreground grey)                 ;; @markup.quote → Grey
   (tree-sitter-hl-face:markup.list :foreground blue)                  ;; @markup.list → TSPunctSpecial
   ;; @parameter.reference → fg (i.e. &param)
   (tree-sitter-hl-face:parameter.reference :foreground fg)            ;; @parameter.reference → Fg
   ;; @strike → grey (strikethrough)
   (tree-sitter-hl-face:strike :foreground grey)                       ;; @strike → Grey

   ;; LSP semantic-token captures from upstream @lsp.type.* links.
   (tree-sitter-hl-face:lsp.type.class :foreground yellow :slant 'italic)
   (tree-sitter-hl-face:lsp.type.comment :foreground grey :slant 'italic)
   (tree-sitter-hl-face:lsp.type.decorator :foreground green :weight 'bold)
   (tree-sitter-hl-face:lsp.type.enum :foreground yellow :slant 'italic)
   (tree-sitter-hl-face:lsp.type.enumMember :foreground blue)
   (tree-sitter-hl-face:lsp.type.events :foreground orange)
   (tree-sitter-hl-face:lsp.type.function :foreground green :weight 'bold)
   (tree-sitter-hl-face:lsp.type.interface :foreground yellow :slant 'italic)
   (tree-sitter-hl-face:lsp.type.keyword :foreground red :slant 'italic)
   (tree-sitter-hl-face:lsp.type.macro :foreground magenta :slant 'italic)
   (tree-sitter-hl-face:lsp.type.method :foreground green :weight 'bold)
   (tree-sitter-hl-face:lsp.type.modifier :foreground orange)
   (tree-sitter-hl-face:lsp.type.namespace :foreground yellow :slant 'italic)
   (tree-sitter-hl-face:lsp.type.number :foreground magenta)
   (tree-sitter-hl-face:lsp.type.operator :foreground orange)
   (tree-sitter-hl-face:lsp.type.parameter :foreground fg)
   (tree-sitter-hl-face:lsp.type.property :foreground blue)
   (tree-sitter-hl-face:lsp.type.regexp :foreground green)
   (tree-sitter-hl-face:lsp.type.string :foreground teal)
   (tree-sitter-hl-face:lsp.type.struct :foreground yellow :slant 'italic)
   (tree-sitter-hl-face:lsp.type.type :foreground yellow :slant 'italic)
   (tree-sitter-hl-face:lsp.type.typeParameter :foreground yellow :slant 'italic)
   (tree-sitter-hl-face:lsp.type.variable :foreground fg)

   ;; Diagnostics / spellcheck / completion UI equivalents.
   (flymake-error :underline `(:style wave :color ,red))
   (flymake-warning :underline `(:style wave :color ,yellow))
   (flymake-note :underline `(:style wave :color ,blue))
   (flycheck-error :underline `(:style wave :color ,red))
   (flycheck-warning :underline `(:style wave :color ,yellow))
   (flycheck-info :underline `(:style wave :color ,blue))
   (eglot-diagnostic-tag-unnecessary-face :foreground grey)
   (eglot-diagnostic-tag-deprecated-face :strike-through t)
   (flyspell-incorrect :underline `(:style wave :color ,red))
   (flyspell-duplicate :underline `(:style wave :color ,yellow))
   (company-tooltip :foreground fg-alt :background base3)
   ;; Upstream PmenuSel defaults to grey2, but that is too bright/tan in Emacs
   ;; minibuffer completion. Use the darker Visual/selection bg instead.
   (company-tooltip-selection :foreground fg :background base3)
   (company-tooltip-common :foreground green :weight 'bold)
   (company-tooltip-common-selection :foreground green :background base3 :weight 'bold)
   (company-tooltip-annotation :foreground grey2)
   (corfu-default :foreground fg-alt :background base3)
   (corfu-current :foreground fg :background base3)
   (corfu-annotations :foreground grey2)
   (vertico-current :foreground fg :background base3)
   (consult-preview-match :foreground bg :background yellow)
   (orderless-match-face-0 :foreground green :weight 'bold)
   (orderless-match-face-1 :foreground yellow :weight 'bold)
   (orderless-match-face-2 :foreground blue :weight 'bold)
   (orderless-match-face-3 :foreground magenta :weight 'bold)

   ;; others
   (isearch :foreground bg :background yellow)
   (lazy-highlight :foreground bg :background orange)
   (region :background base3)

   ;; Markdown headings mirror upstream markdownH1-H6.
   (markdown-header-face-1 :foreground red :weight 'bold)
   (markdown-header-face-2 :foreground orange :weight 'bold)
   (markdown-header-face-3 :foreground yellow :weight 'bold)
   (markdown-header-face-4 :foreground green :weight 'bold)
   (markdown-header-face-5 :foreground blue :weight 'bold)
   (markdown-header-face-6 :foreground magenta :weight 'bold)
  )
  ;; --- extra variables ---------------------
  ()
  )

;;; doom-gruvbox-material-theme.el ends here
