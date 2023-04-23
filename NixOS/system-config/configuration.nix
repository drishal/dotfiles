{ config, pkgs, inputs, lib, ... }:
{
  imports = [
    ./base.nix
    ./gui.nix
    ./nix-config.nix
    ./packages.nix
    ./users.nix
    ./virtualization.nix
    ./searx.nix
    ./hardware-configuration.nix
    ./tlp.nix
  ];

  system.stateVersion = "23.05";
}
