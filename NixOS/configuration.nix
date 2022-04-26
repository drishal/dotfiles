{ config, pkgs, inputs, lib, ... }:
{
  imports =
    [
      ./hardware-configuration.nix
      ./system-config/imports.nix
    ];

  system.stateVersion = "21.05";

}

