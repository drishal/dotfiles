{ config, inputs, pkgs, ... }:
{
  home.packages = with pkgs; [
    neofetch
    man
    nixpkgs-fmt
    # distrobox
    man-pages
    cachix
    neovide
    rust-analyzer
    tdlib
    # neovide
    ispell
    sumneko-lua-language-server 
    # fish
    # firefox
    # exa
    # chromium
    rofi-emoji
    # vivaldi-ffmpeg-codecs
    # vivaldi-widevine
    # # firefox
    # comic-mono
    # (pkgs.nerdfonts.override {
    #   fonts = [ "FiraCode"   "Monofur" ];
    # })
  ];

  # direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };

  # foot
  programs.foot = {
    enable = true;
  };

  #lsd
  programs.lsd = {
    enable=true;
    settings = {
      icons = {
        theme = "fancy";
        separator="  ";
      };
    };
  };

  # caches.cachix = [
  #   {
  #     name = "nix-community";
  #     sha256 = "00lpx4znr4dd0cc4w4q8fl97bdp7q19z1d3p50hcfxy26jz5g21g";
  #   }
  # ];
}
