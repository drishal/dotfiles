{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
{
  programs.bash = {
    enableCompletion = true;
    blesh.enable = true;
  };
  programs.fish.enable = true;
  programs.zsh ={
    enable = true;
  };
  programs.xonsh.enable = true;
  users.users.drishal = {
    shell = pkgs.fish;
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "netdev"
      "network"
      "video"
      "manager"
      "docker"
      "adb"
      "libvirtd"
      "plugdev"
    ];
  };
  security.sudo.extraConfig = ''
    Defaults   insults
  '';

  # fprint
  # services.fprintd.enable = true;
  # security.pam.services = {
  #   # login.fprintAuth = true;
  #   sudo.fprintAuth = true;
  #   # xscreensaver.fprintAuth = true;
  # };

  security.polkit = {
    enable = true;
    extraConfig = ''
      polkit.addAdminRule(function(action, subject) {
        return ["unix-group:wheel"];
      });
    '';
  };
}
