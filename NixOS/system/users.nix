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

  # fprint
  services.fprintd.enable = true;
  security.pam.services.login.fprintAuth = true;
  security.pam.services.sudo.fprintAuth = true;
  security.pam.services.xscreensaver.fprintAuth = true;
}
