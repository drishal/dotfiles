{ config, inputs, pkgs, ... }:
{
  home.packages = with pkgs; [
    # # firefox
    # chromium
    # comic-mono
    # distrobox
    # exa
    # firefox
    # fish
    # neovide
    # vivaldi-ffmpeg-codecs
    # vivaldi-widevine
    cachix
    ispell
    man
    man-pages
    neofetch
    neovide
    nixpkgs-fmt
    nodePackages.create-react-app
    nodePackages.eslint
    nodePackages.js-beautify
    nodePackages.pyright
    nodePackages.react-tools
    # nodePackages.typescript
    # nodePackages.typescript-language-server
    nodePackages.javascript-typescript-langserver
    nodePackages.vscode-html-languageserver-bin
    rofi-emoji
    rust-analyzer
    sumneko-lua-language-server 
    tdlib
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

  # swaylock
  programs.swaylock={
    # enable=true;
    settings={
      image="~/dotfiles/wallpapers/NixOS-1.png";
    };
  };
  # caches.cachix = [
  #   {
  #     name = "nix-community";
  #     sha256 = "00lpx4znr4dd0cc4w4q8fl97bdp7q19z1d3p50hcfxy26jz5g21g";
  #   }
  # ];
}
