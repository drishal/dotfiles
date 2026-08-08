{
  config,
  pkgs,
  inputs,
  lib,
  user,
  ...
}:
{
  programs.bash = {
    completion.enable = true;
    # blesh.enable = true;
  };
  programs.fish = {
    enable = true;
    # vendor.completions.enable = false;
  };

  programs.zsh ={
    enable = true;
    enableCompletion = true;
    enableGlobalCompInit = false;
    promptInit = "";
  };
  programs.xonsh.enable = true;
  users.users.${user} = {
    shell = pkgs.zsh;
    isNormalUser = true;
    linger = true; # keep user@.service (hermes-gateway, syncthing) alive without a login
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
  security.pam.loginLimits = [
    {
      domain = "*";      # applies to all users
      type = "-";        # both soft and hard limit
      item = "memlock";
      value = "unlimited";   # or "unlimited"
    }
  ];

  security.polkit = {
    enable = true;
    extraConfig = ''
      polkit.addAdminRule(function(action, subject) {
        return ["unix-group:wheel"];
      });
    '';
  };
}
