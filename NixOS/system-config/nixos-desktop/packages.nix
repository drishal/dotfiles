{ pkgs, inputs, ... }:

{
  networking.enableIPv6  = false;
  # environment.systemPackages = with pkgs; [
    # inputs.nix-gaming.packages.${pkgs.system}.wine-tkg
    # inputs.nix-gaming.packages.${pkgs.system}.winetricks-git
  # ];
}
