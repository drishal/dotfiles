{ pkgs, ... }:

{
environment.systemPackages = with pkgs; [
    inputs.nix-gaming.packages.${pkgs.system}.wine-tkg
  ];
}
