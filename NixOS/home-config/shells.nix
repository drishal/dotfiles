{ config, inputs, pkgs, ... }:
{
  # lib.fakeSha256

  programs.fish = {
    enable=true;
    interactiveShellInit = ''
    # paths
    fish_add_path ~/.local/bin
    fish_add_path ~/.local/bin/platform-tools
    fish_add_path ~/.node_modules/bin
    fish_add_path ~/.nimble/bin
    fish_add_path ~/.cargo/bin

    #colors
    set fish_color_normal '#98be65'
    set fish_color_autosuggestion '#6272a4'
    set fish_color_command '#98be65'
    set fish_color_error '#ff6c6b'
    set fish_color_param '#98be65'

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
    source ~/dotfiles/aliases.sh

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
     
     { name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src; }
    ];
  };

  # programs.thefuck={
  #   enable=true;
  #   enableFishIntegration=true;
  # };

  # programs.zsh.enable=true;
  # programs.zsh = {
  #   enable=true;
  # };
}
