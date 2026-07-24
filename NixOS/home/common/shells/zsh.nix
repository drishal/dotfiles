{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # fixes an issue with zsh-fzf-tab glitching out on files with quotes
  fzf-tab = pkgs.zsh-fzf-tab.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      substituteInPlace $out/share/fzf-tab/fzf-tab.zsh \
        --replace-fail \
          'builtin compadd "''${args[@]:--Q}" -Q -- "$v[word]"' \
          'builtin compadd "''${args[@]:--Q}" -Q -- "''${v[word]//\\\\/\\}"'
    '';
  });

  # F-Sy-H theme from the stylix base16 palette; mirrors its bundled themes/base16.ini.
  # ANSI→base map: 1→08 2→0B 3→0A 4→0D 5→0E 6→0C 8→03 9→09 10→01 11→02 12→04 14→0F
  c = config.lib.stylix.colors;
  fshStyles = {
    # [base]
    "default" = "none";
    "unknown-token" = "fg=#${c.base08},bold";
    "commandseparator" = "none";
    "redirection" = "none";
    "here-string-tri" = "fg=#${c.base0F}";
    "here-string-text" = "bg=#${c.base02}";
    "here-string-var" = "fg=#${c.base08},bg=#${c.base02}";
    "exec-descriptor" = "fg=#${c.base09},bold";
    "comment" = "fg=#${c.base03}";
    "correct-subtle" = "fg=#${c.base04}";
    "incorrect-subtle" = "fg=#${c.base08}";
    "subtle-separator" = "fg=#${c.base04}";
    "subtle-bg" = "bg=#${c.base01}";
    # [command-point]
    "reserved-word" = "fg=#${c.base0E}";
    "subcommand" = "fg=#${c.base0C}";
    "alias" = "fg=#${c.base0D}";
    "suffix-alias" = "fg=#${c.base0D}";
    "global-alias" = "fg=#${c.base0D},bg=#${c.base02}";
    "builtin" = "fg=#${c.base0D}";
    "function" = "fg=#${c.base0D}";
    "command" = "fg=#${c.base0D}";
    "precommand" = "fg=#${c.base0C}";
    "hashed-command" = "fg=#${c.base0D}";
    "single-sq-bracket" = "fg=#${c.base0D}";
    "double-sq-bracket" = "fg=#${c.base0D}";
    "double-paren" = "fg=#${c.base0E}";
    # [paths]
    "path" = "fg=#${c.base09}";
    "path_pathseparator" = "none";
    "path-to-dir" = "fg=#${c.base09},underline";
    "globbing" = "fg=#${c.base0C}";
    "globbing-ext" = "fg=#${c.base0C},bold";
    # [brackets]
    "paired-bracket" = "bg=#${c.base03}";
    "bracket-level-1" = "fg=#${c.base0A},bold";
    "bracket-level-2" = "fg=#${c.base0C},bold";
    "bracket-level-3" = "fg=#${c.base0B},bold";
    # [arguments]
    "single-hyphen-option" = "fg=#${c.base0A}";
    "double-hyphen-option" = "fg=#${c.base0A}";
    "back-quoted-argument" = "none";
    "single-quoted-argument" = "fg=#${c.base0B}";
    "double-quoted-argument" = "fg=#${c.base0B}";
    "dollar-quoted-argument" = "fg=#${c.base0B}";
    # [in-string]
    "back-dollar-quoted-argument" = "fg=#${c.base0C}";
    "back-or-dollar-double-quoted-argument" = "fg=#${c.base08}";
    # [other]
    "variable" = "fg=#${c.base08}";
    "assign" = "none";
    "assign-array-bracket" = "fg=#${c.base0E}";
    "history-expansion" = "fg=#${c.base0C},bold";
    # [math]
    "mathvar" = "fg=#${c.base08}";
    "mathnum" = "fg=#${c.base09}";
    "matherr" = "fg=#${c.base08},bold";
    # [for-loop]
    "for-loop-variable" = "fg=#${c.base08}";
    "for-loop-number" = "fg=#${c.base09}";
    "for-loop-operator" = "none";
    "for-loop-separator" = "none";
    # [case]
    "case-input" = "fg=#${c.base08}";
    "case-parentheses" = "fg=#${c.base0E}";
    "case-condition" = "bg=#${c.base01}";
  };
  fshStyleLines = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (k: v: "FAST_HIGHLIGHT_STYLES[${k}]=${lib.escapeShellArg v}") fshStyles
  );
in
{

  programs.zsh = {
    enable = true;
    enableCompletion = true;

    defaultKeymap = "emacs";

    # Emits one `setopt <opt>` each; prefix NO_ to unset
    setOptions = [
      "AUTO_CD" # `foo/` cd's into foo
      "AUTO_PUSHD" # cd pushes onto dir stack (then `cd -<TAB>`)
      "PUSHD_IGNORE_DUPS"
      "PUSHD_SILENT"
      "EXTENDED_GLOB"
      "INTERACTIVE_COMMENTS" # `# comments` work interactively
      "LONG_LIST_JOBS"
      "NO_BEEP"
      "HIST_REDUCE_BLANKS"
      "HIST_VERIFY" # don't auto-exec on `!!`, show first
    ];

    completionInit = ''
      autoload -Uz compinit

      # Drop _foo files here to add completions; must join fpath before compinit
      _zcomp_cache="$HOME/.cache/zsh/completions"
      mkdir -p "$_zcomp_cache"
      fpath=("$_zcomp_cache" $fpath)

      zcompdump_dir="$HOME/.cache/zsh"
      zcompdump="$zcompdump_dir/zcompdump-$ZSH_VERSION"
      mkdir -p "$zcompdump_dir"

      # compinit -C skips the fpath scan, so newly-installed packages would
      # silently lose completions; detect that case and do a full rescan.
      _need_full_compinit=false
      if [[ ! -s "$zcompdump" ]]; then
        _need_full_compinit=true
      else
        # .zshrc changed → HM rebuild, unlikely to miss completions but cheap to check.
        if [[ "$zcompdump" -ot "$HOME/.zshrc" ]]; then
          _need_full_compinit=true
        fi
        # Any file in fpath newer than the dump means a new/updated completer.
        if [[ "$_need_full_compinit" == false ]]; then
          for _fp in $fpath; do
            if [[ -d "$_fp" ]] && [[ "$_fp" -nt "$zcompdump" ]]; then
              _need_full_compinit=true
              break
            fi
          done
        fi
      fi

      # -i: skip the insecure-directory audit silently (nix store / HM dirs
      # can trip compaudit and even prompt). Faster, only hits on rebuilds.
      if [[ "$_need_full_compinit" == true ]]; then
        compinit -i -d "$zcompdump"
      else
        compinit -C -d "$zcompdump"
      fi
      unset _need_full_compinit

      # Precompile the dump for faster future startup
      if [[ -s "$zcompdump" && ( ! -s "$zcompdump.zwc" || "$zcompdump" -nt "$zcompdump.zwc" ) ]]; then
        zcompile "$zcompdump"
      fi
    '';
    autosuggestion = {
      enable = true;
      strategy = [
        "history"
        "completion"
      ];
    };
    # Using fast-syntax-highlighting instead — faster and highlights more.
    # Sourced at the end of initContent, after autosuggestions.
    # syntaxHighlighting.enable = true;
    historySubstringSearch = {
      enable = true; # type prefix + Up/Down to filter history
      searchUpKey = [
        "^[[A"
        "\\eOA"
      ]; # CSI + kitty application cursor mode
      searchDownKey = [
        "^[[B"
        "\\eOB"
      ];
    };

    history = {
      path = "${config.home.homeDirectory}/.zsh_history";
      size = 100000; # in-memory (HISTSIZE)
      save = 100000; # on-disk (SAVEHIST); keep >= size so history survives sessions
      expireDuplicatesFirst = true;
      ignoreAllDups = true; # supersedes ignoreDups; drop earlier duplicate entries
      ignoreSpace = true;
      share = true; # SHARE_HISTORY: already implies incremental append + import
      extended = true;
    };

    plugins = [
      {
        # Must be before plugins that wrap widgets (autosuggestions, syntax-highlighting)
        name = "fzf-tab";
        src = "${fzf-tab}/share/fzf-tab";
      }
      {
        # Hand-written completers for tools not in zsh core; added to fpath
        name = "zsh-completions";
        src = "${pkgs.zsh-completions}/share/zsh/site-functions";
      }
    ];

    initContent = ''
      autoload -U +X bashcompinit && bashcompinit
      autoload -Uz add-zsh-hook

      # Native module errors on filenames with single quotes; use the zsh fallback
      zmodload -u aloxaf/fzftab >/dev/null 2>&1
      unset FZF_TAB_MODULE_VERSION 2>/dev/null
      source "$FZF_TAB_HOME"/lib/zsh-ls-colors/ls-colors.zsh fzf-tab-lscolors

      # ---------- key bindings ----------
      # Treat / . _ - as word boundaries (more fish-like word jumps)
      autoload -Uz select-word-style
      select-word-style bash

      # Ctrl+Left / Ctrl+Right
      bindkey '^[[1;5D' backward-word
      bindkey '^[[1;5C' forward-word
      # Alt+Left / Alt+Right (terminals that send these instead)
      bindkey '^[[1;3D' backward-word
      bindkey '^[[1;3C' forward-word

      # Ctrl+Delete / Ctrl+Backspace
      bindkey '^[[3;5~' kill-word
      bindkey '^H'        backward-kill-word   # most terminals
      bindkey '^[^?'      backward-kill-word   # alacritty/some xterms
      bindkey '^[[127;5u' backward-kill-word   # CSI u mode (kitty, foot, wezterm)

      # Home / End / Delete (covers most terminal variants)
      bindkey '^[[H'  beginning-of-line
      bindkey '^[[F'  end-of-line
      bindkey '^[[1~' beginning-of-line
      bindkey '^[[4~' end-of-line
      bindkey '^[[3~' delete-char

      # ---------- autosuggestions ----------
      # Right arrow / End already accept. Add Ctrl+Space if you like:
      # bindkey '^ ' autosuggest-accept

      # ---------- completion polish ----------
      # No native menu: fzf-tab handles selection (and `menu select` fights it).
      zstyle ':completion:*' menu no
      zstyle ':completion:*' verbose yes
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
      if [[ -n "$LS_COLORS" ]]; then
        _zsh_ls_colors=(''${(s.:.)LS_COLORS})
        # dircolors emits Bourne-shell patterns; escape zsh extendedglob tokens
        # that break fzf-tab's native color module (Aloxaf/fzf-tab#280).
        for _zsh_i in {1..$#_zsh_ls_colors}; do
          _zsh_ls_colors[$_zsh_i]=''${_zsh_ls_colors[$_zsh_i]/#[*][#]=/*\\#=}
          _zsh_ls_colors[$_zsh_i]=''${_zsh_ls_colors[$_zsh_i]/#[*][~]=/*\\~=}
        done
        zstyle ':completion:*' list-colors "''${_zsh_ls_colors[@]}"
        unset _zsh_i _zsh_ls_colors
      fi
      # group results by type (fish-like) — fzf-tab needs a non-empty desc format
      zstyle ':completion:*' group-name ""
      zstyle ':completion:*:descriptions' format '[%d]'
      zstyle ':completion:*:warnings'     format '%F{red}no matches: %d%f'

      # completion cache (speeds up slow completers: git, docker, nix, ...)
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path "$HOME/.cache/zsh/compcache"

      # carapace covers ~1000 commands; the rest fall back to file completion

      # ---------- fzf-tab ----------
      zstyle ':fzf-tab:*' switch-group ',' '.'   # cycle groups with , / .
      zstyle ':fzf-tab:*' query-string prefix
      # directory previews when completing cd / zoxide
      zstyle ':fzf-tab:complete:cd:*'          fzf-preview 'eza -1 --icons --color=always $realpath'
      zstyle ':fzf-tab:complete:__zoxide_z:*'  fzf-preview 'eza -1 --icons --color=always $realpath'

      # terminal title
      _zsh_title_precmd()  { print -Pn "\e]0;%n@%m: %~\a" }
      _zsh_title_preexec() {
        local cmd="''${1//[$'\t\r\n']/ }"
        print -Pn "\e]0;%n@%m: %~ — ''${cmd}\a"
      }
      add-zsh-hook precmd  _zsh_title_precmd
      add-zsh-hook preexec _zsh_title_preexec


      # blank line between commands
      __newline_after_first_cmd=false
      _newline_after_command() {
        if $__newline_after_first_cmd; then print
        else __newline_after_first_cmd=true
        fi
      }
      add-zsh-hook precmd _newline_after_command

      # ---------- manual zsh cache cleanup ----------
      zcleanup() {
        local _zcd="$HOME/.cache/zsh"
        local _cur="$_zcd/zcompdump-$ZSH_VERSION"
        echo "Cleaning stale zcompdumps…"

        # Stale version-suffixed dumps in the cache dir
        for _old in "$_zcd"/zcompdump*(N.); do
          [[ "$_old" == "$_cur" || "$_old" == "$_cur.zwc" ]] && continue
          rm -f "$_old" && echo "  rm $_old"
        done

        # Orphaned prezto cache
        [[ -d "$HOME/.cache/prezto" ]] && { rm -rf "$HOME/.cache/prezto" && echo "  rm -rf ~/.cache/prezto"; }

        # Stray dumps in $HOME (default compinit location)
        for _old in "$HOME"/.zcompdump*(N); do
          rm -f "$_old" && echo "  rm $_old"
        done

        unset _old
        echo "Done."
      }

      # ---------- syntax highlighting (MUST be last) ----------
      # F-Sy-H wraps ZLE widgets, so it must load after every `zle -N` above

      # F-Sy-H fetches a secondary theme from GitHub if this file is missing;
      # pre-create it empty so startup stays offline.
      export FAST_WORK_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/fast-syntax-highlighting"
      [[ -d $FAST_WORK_DIR ]] || mkdir -p "$FAST_WORK_DIR"
      [[ -e $FAST_WORK_DIR/secondary_theme.zsh ]] || : > "$FAST_WORK_DIR/secondary_theme.zsh"

      source ${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

      # Applied after sourcing so these win over F-Sy-H's :=-defaults
      typeset -gA FAST_HIGHLIGHT_STYLES
      ${fshStyleLines}
    '';
  };
}
