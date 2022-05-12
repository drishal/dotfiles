{ config, pkgs, inputs, lib, ... }:
{
  imports = [
    ./base.nix
    ./gui.nix
    # ./kernel/kernel.nix
    ./nix-config.nix
    ./packages.nix
    ./users.nix
    ./virtualization.nix
    ./searx.nix
  ];
}
