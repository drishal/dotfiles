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
  # home.packages = with pkgs; [
  #   (pkgs.emacsWithPackagesFromUsePackage {
  #     config = ../../emacs/config.org;
  #     package = pkgs.emacs-unstable-pgtk;
  #     alwaysEnsure = true;
  #     alwaysTangle = true;
  #     extraEmacsPackages =
  #       epkgs: with epkgs; [
  #         use-package
  #         treesit-grammars.with-all-grammars
  #         vterm
  #       ];
  #     override = final: prev: {
  #       rustic = prev.rustic.overrideAttrs { ignoreCompilationError = true; };
  #       eglot-booster = final.melpaBuild {
  #         pname = "eglot-booster";
  #         version = "0.1.0.0.20240616";
  #         src = pkgs.fetchFromGitHub {
  #           owner = "jdtsmith";
  #           repo = "eglot-booster";
  #           rev = "cab7803c4f0adc7fff9da6680f90110674bb7a22";
  #           hash = "sha256-xUBQrQpw+JZxcqT1fy/8C2tjKwa7sLFHXamBm45Fa4Y=";
  #         };
  #       };
  #     };
  #   })
  # ];
  programs = {
    micro = {
      enable = false;
    };
    helix = {
      enable = true;
    };
    emacs = {
      enable = true;
      package = pkgs.emacs-unstable-pgtk;
      extraPackages =
        epkgs: with epkgs; [
          # treesit-grammars.with-all-grammars
        ];
    };
    # nvchad = {
    #   enable = true;
    #   extraPackages = with pkgs; [
    #     emmet-language-server
    #   ];
    #   chadrcConfig = ''
    #   ${builtins.readFile ../../config/nvim/nvchad/chadrc.lua}
    #   '';
    #   hm-activation = true;
    #   backup = true;
    # };
  };
}

# Emacs: just keeping this as a reference if I decide to setup emacs via home manager in the future
# emacs = {
#   enable = true;
#   package = pkgs.emacs-pgtk;
#   extrapackages = epkgs: with epkgs; [
#     treesit-grammars.with-all-grammars
#     vterm
#     telega
#   ];
# };
# colorscheme =
#   lib.concatMapAttrs (name: value: {
#     ${name} = "#${value}";
#   })
# config.colorScheme.palette;
#     config.scheme;
