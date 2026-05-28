{
  config,
  inputs,
  pkgs,
  ...
}:
{
  # lib.fakeSha256
  imports = [
    inputs.direnv-instant.homeModules.direnv-instant
  ];

  programs.fish = {
    enable = true;
    functions = {
      fish_prompt = "";
      fish_right_prompt = "";
    };
    interactiveShellInit = ''
      # paths
      fish_add_path ~/.local/bin
      fish_add_path ~/.local/bin/platform-tools
      fish_add_path ~/.node_modules/bin
      fish_add_path ~/.nimble/bin
      fish_add_path ~/.cargo/bin

      # greeting
      set fish_greeting

      #starship
      # starship init fish | source

      #newline
      function postexec_test --on-event fish_postexec
          echo
      end

      #manpager
      set -x MANROFFOPT "-c" 
      set -x MANPAGER "sh -c 'col -bx | bat -plman'"

      # direnv
      # direnv hook fish | source
      # set -x DIRENV_LOG_FORMAT ""

      #lutris skip 
      set -x LUTRIS_SKIP_INIT 1

      # editor
      set -x EDITOR nvim

      # manpager
      set -x MANROFFOPT "-c" 
      set -x MANPAGER "sh -c 'col -bx | bat -plman'"

      #aliases
      # source ~/dotfiles/scripts/aliases.sh

      #gruvbox 
      # set fish_color_normal D4BE98
      # set fish_color_command A9B665
      # set fish_color_keyword 7DAEA3
      # set fish_color_quote 89B482
      # set fish_color_redirection E78A4E
      # set fish_color_end 7C6F64
      # set fish_color_error EA6962
      # set fish_color_param D4BE98
      # set fish_color_comment 7C6F64
      # set fish_color_selection --background=504945
      # set fish_color_search_match --background=504945
      # set fish_color_operator A9B665
      # set fish_color_escape 7DAEA3
      # set fish_color_autosuggestion 7C6F64
      # set fish_pager_color_progress 8F3F71
      # set fish_pager_color_prefix 89B482
      # set fish_pager_color_completion D4BE98
      # set fish_pager_color_description 8F3F71
      fish_config theme choose "catppuccin-mocha"
    '';
    plugins = [
      {
        name = "catppuccin";
        src = inputs.catppuccin-fish; # ← directly reference the input
      }
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

  # programs.thefuck={
  #   enable=true;
  #   enableFishIntegration=true;
  # };
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      line_break.disabled = true;
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

  # environment.pathsToLink = [ "/share/zsh" ];
  # programs.zsh = {
  #   enable = true;
  #   # enableCompletion = true;
  #   # enableBashCompletion = true;
  #   autosuggestion = {
  #     enable = true;
  #   };
  #   initExtra = ''
  #   source ~/dotfiles/scripts/aliases.sh
  #   '';
  #   syntaxHighlighting.enable = true;
  home.sessionVariables = {
    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
    PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true"; # NixOS-specific: skips glibc/os checks
    PLAYWRIGHT_HOST_PLATFORM_OVERRIDE = "ubuntu-24.04"; # helps with version compatibility
    # Optional: if you want to force a specific browser executable
    # PLAYWRIGHT_LAUNCH_OPTIONS_EXECUTABLE_PATH = "${pkgs.playwright-driver.browsers}/chromium-*/chrome-linux/chrome";  # adjust * to actual rev if needed
  };

  # programs.zsh = {
  #   enable = true;
  #   shellAliases = { };
  #   sessionVariables = {
  #     CCACHE_DIR = "${config.home.homeDirectory}/.ccache";
  #     CCACHE_MAXSIZE = "100G";
  #   };
  #   history = {
  #     path = "${config.home.homeDirectory}/.zsh_history";
  #     size = 10000; # HISTSIZE
  #     save = 1000; # SAVEHIST
  #     expireDuplicatesFirst = true;
  #   };
  #   # autosuggestion.enable = true;
  #   # syntaxHighlighting.enable = true;
  #   initContent = ''
  #     autoload -U +X bashcompinit && bashcompinit
  #     export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$HOME/.node_modules/bin:$PATH"
  #     export PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright-driver.browsers}
  #     export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
  #     export PLAYWRIGHT_HOST_PLATFORM_OVERRIDE="ubuntu-24.04"
  #     bindkey '^[[3;5~' kill-word
  #     bindkey '^[^?' backward-kill-word
  #     bindkey '^[[127;5u' backward-kill-word
  #     # source ~/dotfiles/scripts/aliases.sh
  #     __newline_after_first_cmd=false
  #     newline_after_command() {
  #     if $__newline_after_first_cmd; then
  #         print  # print an empty line
  #     else
  #         __newline_after_first_cmd=true
  #     fi
  #     }

  #     ZSH_AUTOSUGGEST_STRATEGY=(history completion)

  #     add-zsh-hook precmd newline_after_command
  #   '';
  #   enableCompletion = true;
  #   # completionInit = '' '';
  #   plugins = [
  #     {
  #       # Must be before plugins that wrap widgets, such as zsh-autosuggestions or fast-syntax-highlighting
  #       name = "fzf-tab";
  #       src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
  #     }

  #   ];
  #   # Prezto config
  #   prezto = {
  #     enable = true;

  #     # Editor configuration
  #     editor = {
  #       dotExpansion = true;
  #       promptContext = true;
  #     };

  #     # Modules to load
  #     pmodules = [
  #       "environment" # must be loaded first
  #       "archive" # must come before "completion"
  #       "editor" # not sure what this is
  #       "git" # must come before "completion"
  #       "history" # maybe not necessary? needs addl. config
  #       "syntax-highlighting" # not sure if redundant
  #       "history-substring-search" # must be loaded after "syntax-highlighting"
  #       "autosuggestions" # must before loaded after "syntax-highlighting" and "history-substring-search"
  #       "prompt" # just for themes? needs addl. config
  #       "spectrum" # improves 256-color support
  #       "utility" # must be loaded before "completion"
  #       "completion" # must be loaded after "utility"
  #     ];
  #   };
  # };
  # programs.zsh.enable=true;
  # programs.zsh = {
  #   enable=true;
  # };
programs.zsh = {
  enable = true;
  enableCompletion = true;
  autosuggestion.enable = true;
  syntaxHighlighting.enable = true;
  historySubstringSearch = {
    enable = true;   # type prefix + Up/Down to filter history
    searchUpKey = [ "^[[A" "\\eOA" ];    # CSI + kitty application cursor mode
    searchDownKey = [ "^[[B" "\\eOB" ];
  };

  shellAliases = { };

  sessionVariables = {
    CCACHE_DIR = "${config.home.homeDirectory}/.ccache";
    CCACHE_MAXSIZE = "100G";
  };

  history = {
    path = "${config.home.homeDirectory}/.zsh_history";
    size = 10000;
    save = 1000;
    expireDuplicatesFirst = true;
    ignoreDups = true;
    ignoreSpace = true;
    share = true;
    extended = true;
  };

  plugins = [
    {
      # Must be before plugins that wrap widgets (autosuggestions, syntax-highlighting)
      name = "fzf-tab";
      src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
    }
  ];

  initContent = ''
    # ---------- env ----------
    export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$HOME/.node_modules/bin:$PATH"
    export PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright-driver.browsers}
    export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
    export PLAYWRIGHT_HOST_PLATFORM_OVERRIDE="ubuntu-24.04"

    autoload -U +X bashcompinit && bashcompinit
    autoload -Uz add-zsh-hook

    # ---------- shell options (was: prezto environment/history) ----------
    setopt AUTO_CD                 # `foo/` cd's into foo
    setopt AUTO_PUSHD              # cd pushes onto dir stack (then `cd -<TAB>`)
    setopt PUSHD_IGNORE_DUPS
    setopt PUSHD_SILENT
    setopt EXTENDED_GLOB
    setopt INTERACTIVE_COMMENTS    # `# comments` work interactively
    setopt LONG_LIST_JOBS
    setopt NO_BEEP
    setopt HIST_IGNORE_ALL_DUPS
    setopt HIST_REDUCE_BLANKS
    setopt HIST_VERIFY             # don't auto-exec on `!!`, show first
    setopt INC_APPEND_HISTORY

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
    zstyle ':completion:*' menu select
    zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
    zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
    zstyle ':completion:*:descriptions' format '%F{cyan}%d%f'
    zstyle ':completion:*:warnings'     format '%F{red}no matches: %d%f'

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
