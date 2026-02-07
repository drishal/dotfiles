{
  config,
  inputs,
  pkgs,
  ...
}:
{
  # lib.fakeSha256

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

      set fish_color_normal D4BE98
      set fish_color_command A9B665
      set fish_color_keyword 7DAEA3
      set fish_color_quote 89B482
      set fish_color_redirection E78A4E
      set fish_color_end 7C6F64
      set fish_color_error EA6962
      set fish_color_param D4BE98
      set fish_color_comment 7C6F64
      set fish_color_selection --background=504945
      set fish_color_search_match --background=504945
      set fish_color_operator A9B665
      set fish_color_escape 7DAEA3
      set fish_color_autosuggestion 7C6F64
      set fish_pager_color_progress 8F3F71
      set fish_pager_color_prefix 89B482
      set fish_pager_color_completion D4BE98
      set fish_pager_color_description 8F3F71
    '';
    plugins = [
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

      {
        name = "fzf-fish";
        src = pkgs.fishPlugins.fzf-fish.src;
      }
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
    
  programs.zsh = {
    enable = true; 
    shellAliases =  {};
    sessionVariables = {
      CCACHE_DIR = "${config.home.homeDirectory}/.ccache";
      CCACHE_MAXSIZE = "100G";
    };
    history = {
      path = "${config.home.homeDirectory}/.zsh_history";
      size = 10000;   # HISTSIZE
      save = 1000;    # SAVEHIST
      expireDuplicatesFirst = true;
    };
    # autosuggestion.enable = true;
    # syntaxHighlighting.enable = true;
    initContent = ''
      autoload -U +X bashcompinit && bashcompinit
      export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
      # source ~/dotfiles/scripts/aliases.sh
      __newline_after_first_cmd=false
      newline_after_command() {
      if $__newline_after_first_cmd; then
          print  # print an empty line
      else
          __newline_after_first_cmd=true
      fi
      }

      ZSH_AUTOSUGGEST_STRATEGY=(history completion)

      add-zsh-hook precmd newline_after_command
    '';
    enableCompletion = true;
    # completionInit = '' '';
    plugins = [
      {
        # Must be before plugins that wrap widgets, such as zsh-autosuggestions or fast-syntax-highlighting
        name = "fzf-tab";
        src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
      }

    ];
    # Prezto config
    prezto = {
      enable = true;

      # Editor configuration
      editor = {
        dotExpansion = true;
        promptContext = true;
      };

      # Modules to load
      pmodules = [
        "environment" # must be loaded first
        "archive" # must come before "completion"
        "editor" # not sure what this is
        "git" # must come before "completion"
        "history" # maybe not necessary? needs addl. config
        "syntax-highlighting" # not sure if redundant
        "history-substring-search" # must be loaded after "syntax-highlighting"
        "autosuggestions" # must before loaded after "syntax-highlighting" and "history-substring-search"
        "prompt" # just for themes? needs addl. config
        "spectrum" # improves 256-color support
        "utility" # must be loaded before "completion"
        "completion" # must be loaded after "utility"
      ];
    };
  };
  # programs.zsh.enable=true;
  # programs.zsh = {
  #   enable=true;
  # };
}
