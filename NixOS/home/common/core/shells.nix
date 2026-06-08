{
  config,
  inputs,
  pkgs,
  ...
}:
let
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
  # lib.fakeSha256
  imports = [
    inputs.direnv-instant.homeModules.direnv-instant
  ];

  programs.nushell = {
    enable = true;
  };
  programs.fish = {
    enable = true;
    functions = {
      fish_prompt = "";
      fish_right_prompt = "";
    };
    interactiveShellInit = ''
      for c in normal command keyword quote redirection end error param \
               comment operator escape autosuggestion selection search_match \
               cwd cwd_root user host
          set -eU fish_color_$c 2>/dev/null
      end
      for c in progress prefix completion description
          set -eU fish_pager_color_$c 2>/dev/null
      end

      set -g fish_color_normal        ${config.lib.stylix.colors.base05}
      set -g fish_color_command       ${config.lib.stylix.colors.base0B}
      set -g fish_color_keyword       ${config.lib.stylix.colors.base0D}
      set -g fish_color_quote         ${config.lib.stylix.colors.base0C}
      set -g fish_color_redirection   ${config.lib.stylix.colors.base09}
      set -g fish_color_end           ${config.lib.stylix.colors.base03}
      set -g fish_color_error         ${config.lib.stylix.colors.base08}
      set -g fish_color_param         ${config.lib.stylix.colors.base05}
      set -g fish_color_comment       ${config.lib.stylix.colors.base03}
      set -g fish_color_operator      ${config.lib.stylix.colors.base0B}
      set -g fish_color_escape        ${config.lib.stylix.colors.base0D}
      set -g fish_color_autosuggestion ${config.lib.stylix.colors.base03}
      set -g fish_color_selection     ${config.lib.stylix.colors.base05} --bold --background=${config.lib.stylix.colors.base02}
      set -g fish_color_search_match  --background=${config.lib.stylix.colors.base02}
      set -g fish_color_cwd           ${config.lib.stylix.colors.base0B}
      set -g fish_color_cwd_root      ${config.lib.stylix.colors.base08}
      set -g fish_color_user          ${config.lib.stylix.colors.base0B}
      set -g fish_color_host          ${config.lib.stylix.colors.base05}

      set -g fish_pager_color_progress    ${config.lib.stylix.colors.base0E}
      set -g fish_pager_color_prefix      ${config.lib.stylix.colors.base0C}
      set -g fish_pager_color_completion  ${config.lib.stylix.colors.base05}
      set -g fish_pager_color_description ${config.lib.stylix.colors.base0E}
    '';
    plugins = [
      # {
      #   name = "catppuccin";
      #   src = inputs.catppuccin-fish; # ← directly reference the input
      # }
      # Enable a plugin (here grc for colorized command output) from nixpkgs
      # { name = "grc"; src = pkgs.fishPlugins.grc.src; }
      # Manually packaging and enable a plugin
      # {
      #   name = "bass";
      #   src = pkgs.fetchFromGitHub {
      #     owner = "edc";
      #     repo = "Bass";
      #     rev = "79b62958ecf4e87334f24d6743e5766475bcf4d0";
      #     sha256 = "sha256-3d/qL+hovNA4VMWZ0n1L+dSM1lcz7P5CQJyy+/8exTc=";
      #   };
      # }

      # {
      #   name = "fzf-fish";
      #   src = pkgs.fishPlugins.fzf-fish.src;
      # }
    ];
  };

  # Kept zsh-only for now while bringing zsh completions on par with fish.
  programs.carapace = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      line_break.disabled = true;
      # Default nix_shell symbol is "❄️ " (U+2744 + VS16): the variation
      # selector forces emoji presentation, which kitty draws 2 cells wide
      # while wcwidth()/zle counts it as 1. That off-by-one corrupts every
      # zle redraw inside a nix shell (duplicated chars, garbled editing).
      # Use the plain snowflake (no VS16 → text presentation → 1 cell in both).
      nix_shell.symbol = "❄ ";
    };
  };
  programs.bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = ''
        if [ -x /usr/bin/ccache ]; then
          export USE_CCACHE=1
          export CCACHE_EXEC=/usr/bin/ccache
      fi
    '';
  };
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  # programs.direnv-instant.enable = true;

  # PATH shared across all shells (replaces per-shell fish_add_path / export PATH).
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.local/bin/platform-tools"
    "$HOME/.node_modules/bin"
    "$HOME/.nimble/bin"
    "$HOME/.cargo/bin"
  ];

  # Shell-agnostic env vars; Home Manager wires these into fish, bash and zsh.
  home.sessionVariables = {
    EDITOR = "nvim";
    MANROFFOPT = "-c";
    MANPAGER = "sh -c 'col -bx | bat -plman'";
    LUTRIS_SKIP_INIT = "1";

    CCACHE_DIR = "${config.home.homeDirectory}/.ccache";
    CCACHE_MAXSIZE = "100G";

    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
    PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true"; # NixOS-specific: skips glibc/os checks
    PLAYWRIGHT_HOST_PLATFORM_OVERRIDE = "ubuntu-24.04"; # helps with version compatibility
    # Optional: if you want to force a specific browser executable
    # PLAYWRIGHT_LAUNCH_OPTIONS_EXECUTABLE_PATH = "${pkgs.playwright-driver.browsers}/chromium-*/chrome-linux/chrome";  # adjust * to actual rev if needed
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    completionInit = ''
      autoload -Uz compinit

      zcompdump_dir="$HOME/.cache/zsh"
      zcompdump="$zcompdump_dir/zcompdump-$ZSH_VERSION"
      mkdir -p "$zcompdump_dir"

      # Refresh completion cache occasionally, otherwise use fast cached path.
      #
      # - normal compinit: does freshness/security checks and can rebuild dump
      # - compinit -C: skips compaudit + rebuild checks, much faster
      if [[ ! -s "$zcompdump" || "$zcompdump" -ot "$HOME/.zshrc" ]]; then
        # -i: skip the insecure-directory audit silently (nix store / HM dirs
        # can trip compaudit and even prompt). Faster, only hits on rebuilds.
        compinit -i -d "$zcompdump"
      else
        compinit -C -d "$zcompdump"
      fi

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

    shellAliases = { };

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

      # ---------- fzf-tab ----------
      zstyle ':fzf-tab:*' switch-group ',' '.'   # cycle groups with , / .
      zstyle ':fzf-tab:*' query-string prefix
      # directory previews when completing cd / zoxide
      zstyle ':fzf-tab:complete:cd:*'          fzf-preview 'eza -1 --icons --color=always $realpath'
      zstyle ':fzf-tab:complete:__zoxide_z:*'  fzf-preview 'eza -1 --icons --color=always $realpath'

      # ---------- completions for tools carapace doesn't cover ----------
      # carapace handles ~1000 commands; the rest fall back to file completion.
      # Layer in tool-native completions + a `--help`-parsing fallback so these
      # behave more like fish (which auto-generates from man/help pages).
      _zcomp_cache="$HOME/.cache/zsh/completions"
      mkdir -p "$_zcomp_cache"

      # uv / uvx ship their own (clap-generated) zsh completions. Cache them and
      # regenerate only when the binary is newer than the cached file (upgrades).
      if (( $+commands[uv] )); then
        if [[ ! -s "$_zcomp_cache/_uv" || "$commands[uv]" -nt "$_zcomp_cache/_uv" ]]; then
          uv generate-shell-completion zsh > "$_zcomp_cache/_uv"
        fi
        source "$_zcomp_cache/_uv"
      fi
      if (( $+commands[uvx] )); then
        if [[ ! -s "$_zcomp_cache/_uvx" || "$commands[uvx]" -nt "$_zcomp_cache/_uvx" ]]; then
          uvx --generate-shell-completion zsh > "$_zcomp_cache/_uvx"
        fi
        source "$_zcomp_cache/_uvx"
      fi

      # Fish-like fallback: _gnu_generic parses `<cmd> --help` and completes its
      # long options. Good for tools with no native/carapace completer (e.g.
      # claude). Add more space-separated commands here as you hit them.
      compdef _gnu_generic claude

      # ---------- terminal title (was: prezto terminal module) ----------
      _zsh_title_precmd()  { print -Pn "\e]0;%n@%m: %~\a" }
      _zsh_title_preexec() {
        local cmd="''${1//[$'\t\r\n']/ }"
        print -Pn "\e]0;%n@%m: %~ — ''${cmd}\a"
      }
      add-zsh-hook precmd  _zsh_title_precmd
      add-zsh-hook preexec _zsh_title_preexec

      # ---------- `...` -> `../..` (was: prezto editor.dotExpansion) ----------
      # Commented out: causes character duplication with autosuggestions/completion
      # _expand_dots() {
      #   if [[ $LBUFFER = *.. ]]; then LBUFFER+='/..'; else LBUFFER+='.'; fi
      # }
      # zle -N _expand_dots
      # bindkey '.' _expand_dots
      # bindkey -M isearch '.' self-insert   # don't break Ctrl+R

      # ---------- blank line between commands (your original snippet) ----------
      __newline_after_first_cmd=false
      _newline_after_command() {
        if $__newline_after_first_cmd; then print
        else __newline_after_first_cmd=true
        fi
      }
      add-zsh-hook precmd _newline_after_command

      # source ~/dotfiles/scripts/aliases.sh
    '';
  };
}
