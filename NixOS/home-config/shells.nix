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

      #direnv
      direnv hook fish | source
      set -x DIRENV_LOG_FORMAT ""

      #lutris skip 
      set -x LUTRIS_SKIP_INIT 1

      # editor
      set -x EDITOR nvim

      # manpager
      set -x MANROFFOPT "-c" 
      set -x MANPAGER "sh -c 'col -bx | bat -plman'"

      #aliases
      source ~/dotfiles/scripts/aliases.sh

      set fish_color_normal cdd6f4
      set fish_color_command 89b4fa
      set fish_color_param f2cdcd
      set fish_color_keyword f38ba8
      set fish_color_quote a6e3a1
      set fish_color_redirection f5c2e7
      set fish_color_end fab387
      set fish_color_comment 7f849c
      set fish_color_error f38ba8
      set fish_color_gray 6c7086
      set fish_color_selection --background=313244
      set fish_color_search_match --background=313244
      set fish_color_option a6e3a1
      set fish_color_operator f5c2e7
      set fish_color_escape eba0ac
      set fish_color_autosuggestion 6c7086
      set fish_color_cancel f38ba8
      set fish_color_cwd f9e2af
      set fish_color_user 94e2d5
      set fish_color_host 89b4fa
      set fish_color_host_remote a6e3a1
      set fish_color_status f38ba8
      set fish_pager_color_progress 6c7086
      set fish_pager_color_prefix f5c2e7
      set fish_pager_color_completion cdd6f4
      set fish_pager_color_description 6c7086


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
    source ~/dotfiles/scripts/aliases.sh
    '';
  };
  # programs.direnv = {
  #   enable = true;
  #   nix-direnv.enable = true;
  # };

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
    
  #   oh-my-zsh = {
  #     enable = true;
  #     plugins = ["git" "sudo" "direnv"];
  #   };
  # };
  # programs.zsh.enable=true;
  # programs.zsh = {
  #   enable=true;
  # };
}
