{ config, inputs, pkgs, ... }:

# Editors
{
  imports = [
    # ./nixvim.nix
  ];
  programs = {
    micro = {
      enable = false;
    };
    # Emacs
    emacs = {
      enable = true;
      package = pkgs.emacs-pgtk;
      # extraPackages = epkgs: with epkgs; [
      #   vterm telega
      # ];
      # extraPackages = with pkgs; [tree-sitter-grammers.tree-sitter-rust];
      # tree-sitter-grammars.tree-sitter-rust
      extraPackages = epkgs: with epkgs; [
        treesit-grammars.with-all-grammars
        vterm
        telega
      ];
    };
    helix = {
      enable = true;
    };
  };
}

