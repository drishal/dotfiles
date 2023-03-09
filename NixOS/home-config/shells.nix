{ config, inputs, pkgs, ... }:
{
  # lib.fakeSha256

  programs.fish = {
    enable=false;
    interactiveShellInit = ''
    # color schemes
    set fish_color_normal '#98be65'
    set fish_color_autosuggestion '#6272a4'
    set fish_color_command '#98be65'
    set fish_color_error '#ff6c6b'
    set fish_color_param '#98be65'

    # set greeting to blank 
    set fish_greeting

    # starship
    starship init fish | source

    # bass
    # bass source /etc/profile
    bass source ~/dotfiles/.profile

    # add to path
    fish_add_path ~/.local/bin
    '';
    plugins = [
      # Enable a plugin (here grc for colorized command output) from nixpkgs
      # { name = "grc"; src = pkgs.fishPlugins.grc.src; }
      # Manually packaging and enable a plugin
      {
        name = "bass";
        src = pkgs.fetchFromGitHub {
          owner = "edc";
          repo = "Bass";
          rev = "2fd3d2157d5271ca3575b13daec975ca4c10577a";
          # sha256 = "0dbnir6jbwjpjalz14snzd3cgdysgcs3raznsijd6savad3qhijc";
          sha256 = "sha256-fl4/Pgtkojk5AE52wpGDnuLajQxHoVqyphE90IIPYFU=";
        };
      }
    ];
  };
}
