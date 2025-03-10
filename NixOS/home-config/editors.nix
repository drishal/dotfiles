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
  programs = {
    micro = {
      enable = false;
    };
    helix = {
      enable = true;
    };
    emacs = {
      enable = true;
      package = pkgs.emacs-git-pgtk; # .override { withXwidgets = false; };
      extraPackages =
        epkgs: with epkgs; [
          treesit-grammars.with-all-grammars
          vterm
        ];
    };
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
