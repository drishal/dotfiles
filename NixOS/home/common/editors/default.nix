{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

# Editors
{
  imports = [
    ./nixvim.nix
  ];
  home.packages = with pkgs; [
    (pkgs.emacsWithPackagesFromUsePackage {
      config = ../../../../emacs/config.org;
      package = pkgs.emacs-unstable-pgtk;
      alwaysEnsure = true;
      alwaysTangle = true;
      extraEmacsPackages =
        epkgs: with epkgs; [
          use-package
          treesit-grammars.with-all-grammars
          vterm
        ];
      override = final: prev: {
        rustic = prev.rustic.overrideAttrs { ignoreCompilationError = true; };
        eglot-booster = final.melpaBuild {
          pname = "eglot-booster";
          version = "0.1.0.0.20240616";
          src = pkgs.fetchFromGitHub {
            owner = "jdtsmith";
            repo = "eglot-booster";
            rev = "cab7803c4f0adc7fff9da6680f90110674bb7a22";
            hash = "sha256-xUBQrQpw+JZxcqT1fy/8C2tjKwa7sLFHXamBm45Fa4Y=";
          };
        };
      };
    })
  ];
  programs = {
    micro = {
      enable = false;
    };
    helix = {
      enable = true;
      extraConfig = ''
        ${builtins.readFile ../../../../config/helix/config.toml}
      '';
    };
    zed-editor = {
      enable = true;
      extensions = [
        "nix"
        "rust"
      ];
      userSettings = {
        # ui_font_size = 16;
        # buffer_font_size = 16.0;
        telemetry.enable = false;
        vim_mode = true;
        theme = lib.mkForce {
          mode = lib.mkForce "dark";
          dark = lib.mkForce "Gruvbox Material";
          light = lib.mkForce "One Light";
        };
      };
    };
  };
}
