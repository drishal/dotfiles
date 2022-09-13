{ config, pkgs, inputs, lib, ... }:
{
  users.users.drishal = {
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [ "wheel" "netdev" "network" "video" "-manager" "docker" "adb" "libvirtd"];
  };

  security.sudo.extraConfig = ''
    Defaults   insults
  '';

  # fprint
  # services.fprintd.enable = true;
  # security.pam.services = {
  #   login.fprintAuth = true;
  #   sudo.fprintAuth = true;
  #   xscreensaver.fprintAuth = true;
  # };

  security.polkit = {
    enable=true;
    extraConfig=
      ''
      polkit.addAdminRule(function(action, subject) {
        return ["unix-group:wheel"];
      });
      '';
  };
}
