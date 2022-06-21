{ config, inputs, pkgs, ... }:
{
    imports = [
      ./browsers.nix
      ./editors.nix
      ./git.nix
      ./packages.nix
      ./rofi.nix
      ./services.nix
      ./symlinks.nix
  ];

}
