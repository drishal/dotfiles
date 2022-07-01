{ config, inputs, pkgs, ... }:
{
  home.packages = with pkgs; [
    neofetch
    man
    nixpkgs-fmt
    # distrobox
    man-pages
    cachix
    rust-analyzer
    # neovide
    ispell
    # firefox
    # exa
    chromium
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

  # caches.cachix = [
  #   {
  #     name = "nix-community";
  #     sha256 = "00lpx4znr4dd0cc4w4q8fl97bdp7q19z1d3p50hcfxy26jz5g21g";
  #   }
  # ];
}
