{ config, pkgs, inputs, lib, ... }:
{
  users.users.drishal = {
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [ "wheel" "network" "video" "-manager" "docker" ];
  };

  security.sudo.extraConfig = ''
    Defaults   insults
  '';
}
