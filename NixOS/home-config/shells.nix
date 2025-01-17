{
  config,
  inputs,
  pkgs,
  ...
}:
{
  # lib.fakeSha256

  programs.fish = {
    enable = false;
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
      starship init fish | source
      set -x STARSHIP_CONFIG ~/dotfiles/config/starship.toml

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

      #aliases
      source ~/dotfiles/scripts/aliases.sh

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
