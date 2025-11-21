{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
{
  programs.bash = {
    completion.enable = true;
    # blesh.enable = true;
  };
  programs.fish.enable = true;
  programs.zsh ={
    enable = true;
    enableCompletion = false;
    promptInit = "";
  };
  programs.xonsh.enable = true;
  users.users.drishal = {
    shell = pkgs.zsh;
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
      "input"
      "podman"
      "docker"
      "openrazer"
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

  security.pam.services.hyprlock = {};
  security.polkit = {
    enable = true;
    extraConfig = ''
      polkit.addAdminRule(function(action, subject) {
        return ["unix-group:wheel"];
      });
    '';
  };
}
