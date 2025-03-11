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
      config = ../../emacs/config.org;
      package = pkgs.emacs-git-pgtk;
      alwaysEnsure = true;
      extraEmacsPackages =
        epkgs: with epkgs; [
          use-package
          treesit-grammars.with-all-grammars
          vterm
        ];
    })
  ];
  programs = {
    micro = {
      enable = false;
    };
    helix = {
      enable = true;
    };
    # emacs = {
    #   enable = true;
    #   # package = pkgs.emacs-git-pgtk;
    #   package = (
    #     pkgs.emacsWithPackagesFromUsePackage {
    #       config = ../../emacs/config.org;
    #       package = pkgs.emacs-git-pgtk;
    #       alwaysEnsure = false;
    #       extraEmacsPackages = epkgs: [
    #         epkgs.use-package
    #       ];
    #     }
    #   );
    #   extraPackages =
    #     epkgs: with epkgs; [
    #       treesit-grammars.with-all-grammars
    #       vterm
    #     ];
    # };
    # nvchad = {
    #   enable = true;
    #   extraPackages = with pkgs; [
    #     emmet-language-server
    #   ];
    #   chadrcConfig= ''
    #   ${builtins.readFile ../../config/nvim/nvchad/chadrc.lua}
    #   '';
    #   hm-activation = true;
    #   backup = false;
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
