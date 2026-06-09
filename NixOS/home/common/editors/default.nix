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
    ./emacs.nix
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
