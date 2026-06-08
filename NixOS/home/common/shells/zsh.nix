{
  config,
  inputs,
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
in
{

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    completionInit = ''
      autoload -Uz compinit

      # User-managed completion drop-in directory.
      # Drop _foo completion files here and they're picked up on next shell.
      # (Must be added to fpath BEFORE compinit to take effect.)
      _zcomp_cache="$HOME/.cache/zsh/completions"
      mkdir -p "$_zcomp_cache"
      fpath=("$_zcomp_cache" $fpath)

      zcompdump_dir="$HOME/.cache/zsh"
      zcompdump="$zcompdump_dir/zcompdump-$ZSH_VERSION"
      mkdir -p "$zcompdump_dir"

      # Force a full rescan when new completion functions appear on fpath that
      # aren't in the dump.  compinit -C skips this check — fine for speed, but
      # means newly-installed packages (system or HM) silently lose completions.
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

      # Precompile the dump for faster future startup.
      # Only do this when missing or older than the dump.
      if [[ -s "$zcompdump" && ( ! -s "$zcompdump.zwc" || "$zcompdump" -nt "$zcompdump.zwc" ) ]]; then
        zcompile "$zcompdump"
      fi
    '';
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
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
        # Large set of hand-written completers for tools not in zsh core.
        # Adds its completers to fpath; picked up by compinit.
        name = "zsh-completions";
        src = "${pkgs.zsh-completions}/share/zsh/site-functions";
      }
    ];

    initContent = ''
      autoload -U +X bashcompinit && bashcompinit
      autoload -Uz add-zsh-hook

      # fzf-tab's native module can error on filenames containing single
      # quotes. Unload it so fzf-tab uses the pure-zsh color fallback.
      zmodload -u aloxaf/fzftab >/dev/null 2>&1
      unset FZF_TAB_MODULE_VERSION 2>/dev/null
      source "$FZF_TAB_HOME"/lib/zsh-ls-colors/ls-colors.zsh fzf-tab-lscolors

      # ---------- shell options (was: prezto environment/history) ----------
      setopt AUTO_CD                 # `foo/` cd's into foo
      setopt AUTO_PUSHD              # cd pushes onto dir stack (then `cd -<TAB>`)
      setopt PUSHD_IGNORE_DUPS
      setopt PUSHD_SILENT
      setopt EXTENDED_GLOB
      setopt INTERACTIVE_COMMENTS    # `# comments` work interactively
      setopt LONG_LIST_JOBS
      setopt NO_BEEP
      # HIST_IGNORE_ALL_DUPS / SHARE_HISTORY are set via programs.zsh.history
      # (ignoreAllDups / share); SHARE_HISTORY already implies incremental append.
      setopt HIST_REDUCE_BLANKS
      setopt HIST_VERIFY             # don't auto-exec on `!!`, show first

      # ---------- key bindings (was: prezto editor) ----------
      bindkey -e  # emacs mode

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
      ZSH_AUTOSUGGEST_STRATEGY=(history completion)
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

      #  completions for tools carapace doesn't cover 
      # carapace handles ~1000 commands; the rest fall back to file completion.
      # Layer in tool-native completions + a `--help`-parsing fallback so these
      # behave more like fish (which auto-generates from man/help pages).
      # (User completion drop-in dir is set up in completionInit above.)

      # ---------- fzf-tab ----------
      zstyle ':fzf-tab:*' switch-group ',' '.'   # cycle groups with , / .
      zstyle ':fzf-tab:*' query-string prefix
      # directory previews when completing cd / zoxide
      zstyle ':fzf-tab:complete:cd:*'          fzf-preview 'eza -1 --icons --color=always $realpath'
      zstyle ':fzf-tab:complete:__zoxide_z:*'  fzf-preview 'eza -1 --icons --color=always $realpath'

      # terminal title (was: prezto terminal module)
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
    '';
  };
}
