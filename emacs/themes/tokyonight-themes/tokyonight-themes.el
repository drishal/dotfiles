;;; tokyonight-themes.el --- TokyoNight themes. -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(defgroup tokyonight-themes ()
  "TokyoNight themes."
  :group 'faces)

(defconst tokyonight-themes-faces
  '(
    ;; basic faces
    `(default ((,c :foreground ,fg :background ,bg)))
    `(bold ((,c :weight bold)))
    `(italic ((,c :slant italic)))
    `(bold-italic ((,c :inherit (bold italic))))
    `(underline ((,c :underline t)))
    `(cursor ((,c :background ,fg)))
    `(fringe ((,c :foreground ,fg-dark :background ,bg-dark)))
    `(menu ((,c :background ,bg-dark :foreground ,fg)))
    `(scroll-bar ((,c :background ,bg-dark :foreground ,fg-dark)))
    `(tool-bar ((,c :background ,bg-dark :foreground ,fg)))
    `(button ((,c :background unspecified :foreground ,blue1 :underline ,blue1)))
    `(link ((,c :inherit button)))
    `(link-visited ((,c :background ,bg :foreground ,magenta :underline ,magenta)))
    `(match ((,c :foreground ,blue :background ,bg :inverse-video t)))
    `(shadow ((,c :foreground ,dark5)))
    `(minibuffer-prompt ((,c :foreground ,magenta :background unspecified)))
    `(region ((,c :background ,dark3 :foreground ,fg :extend t)))
    `(secondary-selection ((,c :background ,bg-hl :foreground unspecified)))
    `(trailing-whitespace ((,c :foreground ,fg :background ,red1)))
    `(border ((,c :background ,bg :foreground ,fg-gutter)))
    `(vertical-border ((,c :foreground ,fg-gutter)))
    `(tooltip ((,c :background ,bg-hl :foreground ,fg)))
    `(highlight ((,c :background ,bg-hl)))
    `(error ((,c :foreground ,red)))
    `(warning ((,c :foreground ,orange)))
    `(success ((,c :foreground ,green)))

    ;; font-lock
    `(font-lock-bracket-face ((,c :foreground ,blue1)))
    `(font-lock-builtin-face ((,c :foreground ,purple)))
    `(font-lock-comment-face ((,c :foreground ,comment :slant italic)))
    `(font-lock-comment-delimiter-face ((,c :foreground ,comment :slant italic)))
    `(font-lock-constant-face ((,c :foreground ,orange)))
    `(font-lock-doc-face ((,c :foreground ,green2 :slant italic)))
    `(font-lock-function-name-face ((,c :foreground ,blue)))
    `(font-lock-keyword-face ((,c :foreground ,magenta :slant italic)))
    `(font-lock-negation-char-face ((,c :inherit error)))
    `(font-lock-operator-face ((,c :foreground ,blue5)))
    `(font-lock-preprocessor-face ((,c :foreground ,cyan)))
    `(font-lock-regexp-grouping-backslash ((,c :foreground ,yellow)))
    `(font-lock-regexp-grouping-construct ((,c :foreground ,magenta)))
    `(font-lock-string-face ((,c :foreground ,green)))
    `(font-lock-type-face ((,c :foreground ,blue1)))
    `(font-lock-variable-name-face ((,c :foreground ,blue2)))
    `(font-lock-warning-face ((,c :foreground ,yellow)))

    ;; ansi-color
    `(ansi-color-black ((,c :background "black" :foreground "black")))
    `(ansi-color-blue ((,c :background ,blue :foreground ,blue)))
    `(ansi-color-bold ((,c :inherit bold)))
    `(ansi-color-cyan ((,c :background ,cyan :foreground ,cyan)))
    `(ansi-color-green ((,c :background ,green :foreground ,green)))
    `(ansi-color-magenta ((,c :background ,magenta :foreground ,magenta)))
    `(ansi-color-red ((,c :background ,red1 :foreground ,red1)))
    `(ansi-color-white ((,c :background "gray65" :foreground "gray65")))
    `(ansi-color-yellow ((,c :background ,orange :foreground ,orange)))
    `(ansi-color-bright-black ((,c :background "gray35" :foreground "gray35")))
    `(ansi-color-bright-blue ((,c :background ,blue1 :foreground ,blue1)))
    `(ansi-color-bright-cyan ((,c :background ,blue6 :foreground ,blue6)))
    `(ansi-color-bright-green ((,c :background ,green1 :foreground ,green1)))
    `(ansi-color-bright-magenta ((,c :background ,magenta2 :foreground ,magenta2)))
    `(ansi-color-bright-red ((,c :background ,red :foreground ,red)))
    `(ansi-color-bright-white ((,c :background "white" :foreground "white")))
    `(ansi-color-bright-yellow ((,c :background ,yellow :foreground ,yellow)))

    ;; ace-window
    `(aw-background-face ((,c :foreground "gray50")))
    `(aw-key-face ((,c :inherit font-lock-builtin-face)))
    `(aw-leading-char-face ((,c :inherit bold :height 1.5 :foreground ,red)))
    `(aw-minibuffer-leading-char-face ((,c :inherit aw-key-face)))
    `(aw-mode-line-face ((,c :inherit bold)))

    ;; avy
    `(avy-background-face ((,c :background ,bg-dark :foreground ,fg-dark :extend t)))
    `(avy-goto-char-timer-face ((,c :inherit bold :background ,bg-hl)))
    `(avy-lead-face ((,c :inherit bold :background ,blue :foreground ,bg)))
    `(avy-lead-face-0 ((,c :inherit bold :background ,magenta :foreground ,bg)))
    `(avy-lead-face-1 ((,c :background ,dark3)))
    `(avy-lead-face-2 ((,c :inherit bold :background ,yellow :foreground ,bg)))

    ;; bookmark
    `(bookmark-face ((,c :inherit success)))
    `(bookmark-menu-bookmark ((,c :inherit bold)))

    ;; calendar and diary
    `(calendar-month-header ((,c :inherit bold)))
    `(calendar-today ((,c :inherit bold :underline t)))
    `(calendar-weekday-header ((,c :foreground ,cyan)))
    `(calendar-weekend-header ((,c :foreground ,red1)))
    `(diary ((,c :foreground ,cyan)))
    `(diary-anniversary ((,c :foreground ,red1)))
    `(diary-time ((,c :foreground ,cyan)))
    `(holiday ((,c :foreground ,red1)))

    ;; compilation
    `(compilation-info ((,c :foreground ,green :weight bold)))
    `(compilation-warning ((,c :foreground ,orange :weight bold)))
    `(compilation-error ((,c :foreground ,red :weight bold)))
    `(compilation-line-number ((,c :inherit shadow)))
    `(compilation-column-number ((,c :inherit compilation-line-number)))
    `(compilation-mode-line-exit ((,c :foreground ,green :weight bold)))
    `(compilation-mode-line-fail ((,c :foreground ,red :weight bold)))
    `(compilation-mode-line-run ((,c :foreground ,orange :weight bold)))

    ;; completions
    `(completions-annotations ((,c :foreground ,comment :background unspecified :slant italic)))
    `(completions-common-part ((,c :foreground ,blue1 :background unspecified)))
    `(completions-first-difference ((,c :foreground ,purple :background unspecified :weight bold)))
    `(completions-highlight ((,c :background ,bg-hl :weight bold)))

    ;; corfu
    `(corfu-default ((,c :foreground ,fg :background ,bg-dark)))
    `(corfu-current ((,c :foreground ,fg :background ,bg-hl :weight bold)))
    `(corfu-bar ((,c :foreground ,fg :background ,dark3)))
    `(corfu-border ((,c :foreground ,fg :background ,dark5)))

    ;; custom (M-x customize)
    `(custom-button ((,c :background ,dark3 :foreground ,fg :box(:line-width 1 :color ,dark5 :style release-button))))
    `(custom-button-mouse ((,c :inherit (highlight custom-button))))
    `(custom-button-pressed ((,c :inherit (secondary-selection custom-button))))
    `(custom-changed ((,c :background ,dark3)))
    `(custom-comment ((,c :inherit shadow)))
    `(custom-comment-tag ((,c :inherit (bold shadow))))
    `(custom-invalid ((,c :inherit error :strike-through t)))
    `(custom-modified ((,c :inherit custom-changed)))
    `(custom-rogue ((,c :inherit custom-invalid)))
    `(custom-set ((,c :inherit success)))
    `(custom-state ((,c :foreground ,orange)))
    `(custom-themed ((,c :inherit custom-changed)))
    `(custom-variable-obsolete ((,c :inherit shadow)))
    `(custom-face-tag ((,c :inherit bold :foreground ,blue)))
    `(custom-group-tag ((,c :inherit bold :foreground ,magenta)))
    `(custom-group-tag-1 ((,c :inherit bold :foreground ,orange)))
    `(custom-variable-tag ((,c :inherit bold :foreground ,blue2)))

    ;; diff
    `(diff-added ((,c :foreground ,green :background ,bg-hl)))
    `(diff-changed ((,c :foreground ,yellow :background ,bg-hl)))
    `(diff-changed-unspecified ((,c :inherit diff-changed)))
    `(diff-removed ((,c :foreground ,red :background ,bg-hl)))
    `(diff-indicator-added ((,c :inherit diff-added)))
    `(diff-indicator-changed ((,c :inherit diff-changed)))
    `(diff-indicator-removed ((,c :inherit diff-removed)))
    `(diff-refine-added ((,c :inherit diff-added :inverse-video t)))
    `(diff-refine-changed ((,c :inherit diff-changed :inverse-video t)))
    `(diff-refine-removed ((,c :inherit diff-removed :inverse-video t)))
    `(diff-context (()))
    `(diff-error ((,c :inherit error)))
    `(diff-file-header ((,c :inherit bold)))
    `(diff-function ((,c :background ,dark3)))
    `(diff-header (()))
    `(diff-hunk-header ((,c :inherit bold :background ,dark3)))
    `(diff-index ((,c :slant italic)))
    `(diff-nonexistent ((,c :inherit bold)))

    ;; diff-hl
    `(diff-hl-change ((,c :foreground ,bg :background ,yellow)))
    `(diff-hl-delete ((,c :foreground ,bg :background ,red)))
    `(diff-hl-insert ((,c :foreground ,bg :background ,green)))
    `(diff-hl-reverted-hunk-highlight ((,c :foreground ,bg :background ,fg)))

    ;; dired
    `(dired-broken-symlink ((,c :inherit button :foreground ,red)))
    `(dired-directory ((,c :foreground ,blue1)))
    `(dired-flagged ((,c :foreground ,red :weight bold :inverse-video t)))
    `(dired-header ((,c :inherit bold)))
    `(dired-ignored ((,c :inherit shadow)))
    `(dired-mark ((,c :inherit bold)))
    `(dired-marked ((,c :foreground ,cyan :weight bold :inverse-video t)))
    `(dired-perm-write ((,c :inherit shadow)))
    `(dired-symlink ((,c :foreground ,cyan :background ,bg :underline ,cyan)))
    `(dired-warning ((,c :inherit warning)))

    ;; eldoc-box
    `(eldoc-box-body ((,c :inherit tooltip)))
    `(eldoc-box-border ((,c :foreground ,fg :background ,dark5)))

    ;; eshell
    `(eshell-prompt ((,c :foreground ,magenta :weight bold)))
    `(eshell-ls-archive ((,c :foreground ,red)))
    `(eshell-ls-backup ((,c :inherit font-lock-comment-face)))
    `(eshell-ls-clutter ((,c :inherit font-lock-comment-face)))
    `(eshell-ls-directory ((,c :foreground ,blue)))
    `(eshell-ls-executable ((,c :foreground ,green)))
    `(eshell-ls-missing ((,c :inherit font-lock-warning-face)))
    `(eshell-ls-product ((,c :inherit font-lock-doc-face)))
    `(eshell-ls-special ((,c :foreground ,yellow :weight bold)))
    `(eshell-ls-symlink ((,c :foreground ,cyan :weight bold)))
    `(eshell-ls-unreadable ((,c :foreground ,fg)))

    ;; flymake
    `(flymake-error ((,c :underline (:color ,red))))
    `(flymake-warning ((,c :underline (:color ,yellow))))
    `(flymake-note ((,c :underline (:color ,cyan))))

    ;; flycheck
    `(flycheck-error ((,c :underline (:color ,red))))
    `(flycheck-warning ((,c :underline (:color ,yellow))))
    `(flycheck-info ((,c :underline (:color ,cyan))))

    ;; git-gutter
    `(git-gutter-fr:added ((,c :foreground ,green)))
    `(git-gutter-fr:deleted ((,c :foreground ,red)))
    `(git-gutter-fr:modified ((,c :foreground ,yellow)))

    ;; flyspell
    `(flyspell-duplicate ((,c :underline (:style wave :color ,orange))))
    `(flyspell-incorrect ((,c :underline (:style wave :color ,red))))

    ;; hl-line
    `(hl-line ((,c :background ,bg-hl :extend t)))

    ;; hl-todo
    `(hl-todo ((,c :inherit (bold font-lock-comment-face) :foreground ,red)))

    ;; icomplete
    `(icomplete-first-match ((,c :foreground ,blue1 :weight bold)))
    `(icomplete-selected-match ((,c :background ,bg-hl :weight bold)))

    ;; ido
    `(ido-first-match ((,c :foreground ,blue1 :weight bold)))
    `(ido-incomplete-regexp ((,c :inherit error :weight bold)))
    `(ido-indicator ((,c :inherit bold)))
    `(ido-only-match ((,c :inherit ido-first-match)))
    `(ido-subdir ((,c :foreground ,blue1)))
    `(ido-virtual ((,c :foreground ,purple)))

    ;; isearch
    `(isearch ((,c :foreground ,yellow :background ,bg :inverse-video t)))
    `(isearch-fail ((,c :foreground ,red :background ,bg :inverse-video t)))
    `(isearch-group-1 ((,c :foreground ,blue1 :background ,bg :inverse-video t)))
    `(isearch-group-2 ((,c :foreground ,green1 :background ,bg :inverse-video t)))
    `(lazy-highlight ((,c :foreground ,cyan :background ,bg :inverse-video t)))

    ;; line-number
    `(line-number ((,c :inherit default :background ,bg-dark :foreground ,fg-dark)))
    `(line-number-current-line ((,c :inherit (bold line-number) :background ,fg-gutter :foreground ,fg)))
    `(line-number-major-tick ((,c :inherit line-number :foreground ,red)))
    `(line-number-minor-tick ((,c :inherit line-number :foreground ,fg-dark)))

    ;; message
    `(message-cited-text-1 ((,c :foreground ,blue)))
    `(message-cited-text-2 ((,c :foreground ,yellow)))
    `(message-cited-text-3 ((,c :foreground ,cyan)))
    `(message-cited-text-4 ((,c :foreground ,red)))
    `(message-header-name ((,c :inherit bold)))
    `(message-header-newsgroups ((,c :inherit message-header-other)))
    `(message-header-to ((,c :inherit bold :foreground ,magenta)))
    `(message-header-cc ((,c :foreground ,magenta)))
    `(message-header-subject ((,c :inherit bold :foreground ,magenta2)))
    `(message-header-xheader ((,c :inherit message-header-other)))
    `(message-header-other ((,c :foreground ,purple)))
    `(message-mml ((,c :foreground ,blue1)))
    `(message-separator ((,c :background ,dark3)))

    ;; mode-line / header-line
    `(mode-line ((,c :foreground ,fg :background ,bg-dark :weight normal :box (:line-width 1 :color ,bg-dark))))
    `(mode-line-buffer-id ((,c :inherit bold)))
    `(mode-line-active ((,c :inherit mode-line)))
    `(mode-line-inactive ((,c :foreground ,dark5 :background ,bg-dark :weight normal :box (:line-width 1 :color ,bg-dark))))
    `(mode-line-emphasis ((,c :foreground ,blue)))
    `(mode-line-highlight ((,c :foreground ,bg :background ,blue :box nil)))
    `(header-line ((,c :inherit mode-line)))
    `(header-line-highlight ((,c :inherit mode-line-highlight)))

    ;; multiple-cursors
    `(mc/cursor-bar-face ((,c :foreground ,fg :background ,bg :height 1)))
    `(mc/cursor-face ((,c :inverse-video t)))
    `(mc/region-face ((,c :inherit region)))

    ;; orderless
    `(orderless-match-face-0 ((,c :foreground ,blue1)))
    `(orderless-match-face-1 ((,c :foreground ,purple)))
    `(orderless-match-face-2 ((,c :foreground ,cyan)))
    `(orderless-match-face-3 ((,c :foreground ,yellow)))

    ;; regexp-builder
    `(reb-match-0 ((,c :foreground ,blue1 :background ,bg :inverse-video t)))
    `(reb-match-1 ((,c :foreground ,green1 :background ,bg :inverse-video t)))
    `(reb-match-2 ((,c :foreground ,red1 :background ,bg :inverse-video t)))
    `(reb-match-3 ((,c :foreground ,magenta2 :background ,bg :inverse-video t)))
    `(reb-regexp-grouping-backslash ((,c :inherit font-lock-regexp-grouping-backslash)))
    `(reb-regexp-grouping-construct ((,c :inherit font-lock-regexp-grouping-construct)))

    ;; ruler-mode
    `(ruler-mode-column-number ((,c :inherit ruler-mode-default)))
    `(ruler-mode-comment-column ((,c :inherit ruler-mode-default :foreground ,red)))
    `(ruler-mode-current-column ((,c :inherit ruler-mode-default :background ,bg-dark :foreground ,fg)))
    `(ruler-mode-default ((,c :inherit default :background ,bg-dark :foreground ,fg-dark)))
    `(ruler-mode-fill-column ((,c :inherit ruler-mode-default :foreground ,green)))
    `(ruler-mode-fringes ((,c :inherit ruler-mode-default :foreground ,cyan)))
    `(ruler-mode-goal-column ((,c :inherit ruler-mode-default :foreground ,blue)))
    `(ruler-mode-margins ((,c :inherit ruler-mode-default :foreground ,dark3)))
    `(ruler-mode-pad ((,c :inherit ruler-mode-default :background ,bg :foreground ,dark5)))
    `(ruler-mode-tab-stop ((,c :inherit ruler-mode-default :foreground ,yellow)))

    ;; shell
    `(sh-heredoc ((,c :inherit font-lock-string-face)))
    `(sh-quoted-exec ((,c :inherit font-lock-builtin-face)))

    ;; show-paren-mode
    `(show-paren-match ((,c :background ,blue :foreground ,bg)))
    `(show-paren-match-expression ((,c :background ,magenta :foreground ,bg)))
    `(show-paren-mismatch ((,c :background ,red :foreground ,bg)))

    ;; speedbar
    `(speedbar-button-face ((,c :inherit button)))
    `(speedbar-directory-face ((,c :inherit bold :foreground ,blue2)))
    `(speedbar-file-face ((,c :foreground ,fg)))
    `(speedbar-highlight-face ((,c :inherit highlight)))
    `(speedbar-selected-face ((,c :foreground ,cyan :weight bold :inverse-video t)))
    `(speedbar-separator-face ((,c :background ,dark3 :foreground ,fg)))
    `(speedbar-tag-face ((,c :foreground ,magenta2)))

    ;; symbol-overlay
    `(symbol-overlay-default-face ((,c :background ,blue7)))
    `(symbol-overlay-face-1 ((,c :background ,blue :foreground "black")))
    `(symbol-overlay-face-2 ((,c :background ,magenta :foreground "black")))
    `(symbol-overlay-face-3 ((,c :background ,yellow :foreground "black")))
    `(symbol-overlay-face-4 ((,c :background ,magenta2 :foreground "black")))
    `(symbol-overlay-face-5 ((,c :background ,red :foreground "black")))
    `(symbol-overlay-face-6 ((,c :background ,orange :foreground "black")))
    `(symbol-overlay-face-7 ((,c :background ,green :foreground "black")))
    `(symbol-overlay-face-8 ((,c :background ,cyan :foreground "black")))

    ;; tab-line / tab-bar
    `(tab-line ((,c :foreground ,fg-dark :background ,bg-dark)))
    `(tab-line-tab ((,c :foreground ,fg :background ,bg)))
    `(tab-line-tab-inactive ((,c :foreground ,fg-dark :background ,bg-dark)))
    `(tab-line-tab-inactive-alternate ((,c :inherit tab-line-tab-inactive)))
    `(tab-line-tab-current ((,c :foreground ,fg :background ,bg)))
    `(tab-bar ((,c :foreground ,fg-dark :background ,bg-dark)))
    `(tab-bar-tab ((,c :foreground ,fg :background ,bg)))
    `(tab-bar-tab-inactive ((,c :foreground ,fg-dark :background ,bg-dark)))

    ;; vertico
    `(vertico-current ((,c :background ,bg-hl :weight bold)))

    ;; vundo
    `(vundo-default ((,c :inherit shadow)))
    `(vundo-highlight ((,c :inherit (bold vundo-node) :foreground ,red)))
    `(vundo-last-saved ((,c :inherit (bold vundo-node) :foreground ,blue)))
    `(vundo-saved ((,c :inherit vundo-mode :foreground ,blue5)))

    ;; which-func-mode
    `(which-func ((,c :inherit bold :foreground ,blue)))

    ;; which-key
    `(which-key-command-description-face ((,c :foreground ,fg)))
    `(which-key-group-description-face ((,c :foreground ,cyan)))
    `(which-key-highlighted-command-face ((,c :inherit warning :underline t)))
    `(which-key-key-face ((,c :foreground ,blue1 :weight bold)))
    `(which-key-local-map-description-face ((,c :foreground ,fg)))
    `(which-key-note-face ((,c :inherit shadow)))
    `(which-key-separator-face ((,c :inherit shadow)))
    `(which-key-special-key-face ((,c :inherit error :weight bold)))

    ;; whitespace-mode
    `(whitespace-big-indent ((,c :background ,red1)))
    `(whitespace-empty ((,c :background unspecified)))
    `(whitespace-hspace ((,c :background unspecified :foreground ,fg-dark)))
    `(whitespace-indentation ((,c :background unspecified :foreground ,fg-dark)))
    `(whitespace-line ((,c :background unspecified :foreground ,orange)))
    `(whitespace-newline ((,c :background unspecified :foreground ,fg-dark)))
    `(whitespace-space ((,c :background unspecified :foreground ,fg-dark)))
    `(whitespace-space-after-tab ((,c :inherit warning :background unspecified)))
    `(whitespace-space-before-tab ((,c :inherit warning :background unspecified)))
    `(whitespace-tab ((,c :background unspecified :foreground ,fg-dark)))
    `(whitespace-trailing ((,c :background ,red1)))

    ;; widget
    `(widget-button ((,c :inherit bold :foreground ,blue1)))
    `(widget-button-pressed ((,c :inherit widget-button :foreground ,magenta)))
    `(widget-documentation ((,c :inherit font-lock-doc-face)))
    `(widget-field ((,c :background ,dark3 :foreground ,fg :extend nil)))
    `(widget-inactive ((,c :background ,bg-dark :foreground ,fg-dark)))
    `(widget-single-line-field ((,c :inherit widget-field)))

    ;; window-divider-mode
    `(window-divider ((,c :foreground ,fg-dark)))
    `(window-divider-first-pixel ((,c :foreground ,dark3)))
    `(window-divider-last-pixel ((,c :foreground ,dark3)))
    )
  "Face specs for use with `tokyonight-themes-theme'.")

(defconst tokyonight-themes-custom-variables
  '(
    ;;;; ansi-colors
    `(ansi-color-names-vector [,bg ,red ,green ,yellow ,blue ,magenta ,cyan ,fg])

    ;;;; hl-todo
    `(hl-todo-keyword-faces
      '(("HOLD" . ,yellow)
        ("TODO" . ,red)
        ("NEXT" . ,fg-dark)
        ("THEM" . ,fg-dark)
        ("PROG" . ,cyan)
        ("OKAY" . ,cyan)
        ("DONT" . ,yellow)
        ("FAIL" . ,red)
        ("BUG" . ,red)
        ("DONE" . ,cyan)
        ("NOTE" . ,yellow)
        ("KLUDGE" . ,yellow)
        ("HACK" . ,yellow)
        ("TEMP" . ,yellow)
        ("FIXME" . ,red)
        ("XXX+" . ,red)
        ("REVIEW" . ,cyan)
        ("DEPRECATED" . ,cyan)))
  )
  "Custom variables for `tokyonight-themes-theme'.")

;;; Theme macros

;;;; Instantiate a tokyonight theme

;;;###autoload
(defmacro tokyonight-themes-theme (name palette &optional overrides)
  "Bind NAME's color PALETTE. Optional OVERRIDES are appended to PALETTE."
  (declare (indent 0))
  `(let* ((c '((class color) (min-colors 256)))
          ,@(mapcar (lambda (cons)
                     (list (car cons) (cdr cons)))
                    (append (symbol-value palette) (symbol-value overrides))))
     (custom-theme-set-faces ',name ,@tokyonight-themes-faces)
     (custom-theme-set-variables ',name ,@tokyonight-themes-custom-variables)))

;;;; Use theme colors

(defmacro tokyonight-themes-with-colors (&rest body)
  "Evaluate BODY with colors from current palette bound."
  (declare (indent 0))
  (let* ((theme (or (car (seq-filter (lambda (th)
                                      (string-prefix-p "tokyonight-" (symbol-name th)))
                                     custom-enabled-themes))
                    (user-error "No enabled tokyonight theme could be found"))))
    `(let* ((c '((class color) (min-colors 256)))
            ,@(mapcar (lambda (cons)
                        (list (car cons) (cdr cons)))
                      (append (symbol-value (intern (format "%s-palette" theme)))
                              (symbol-value (intern (format "%s-palette-overrides" theme))))))
      ,@body)))

;;;; Add themes from package to path

;;;###autoload
(when load-file-name
  (let ((dir (file-name-directory load-file-name)))
    (unless (equal dir (expand-file-name "themes/" data-directory))
      (add-to-list 'custom-theme-load-path dir))))

(provide 'tokyonight-themes)
;;; tokyonight-themes.el ends here
