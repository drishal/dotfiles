{ config, pkgs, inputs, lib, ... }:
{
  imports =
    [
      ./hardware-configuration.nix
      ./system/imports.nix
    ];

  system.stateVersion = "21.05";

}

