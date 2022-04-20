{ config, pkgs, inputs, lib, ... }:

{
  services.xserver = {
    enable = true;

    # window wmanagers
    windowManager = {
      qtile.enable = true;

      xmonad = {
        enable = true;
        enableContribAndExtras = true;
      };


      awesome.enable = true;
      dwm.enable = true;
    };

    # Desktop Environment
    desktopManager = {
      plasma5.enable = true;
      xfce.enable = true;
      # lxqt.enable = true;
      # gnome.enable = true;
    };

    # displayManager.gdm.enable = true;
    displayManager.sddm.enable = true;

    # displayManager.lightdm = {
    #   enable = true;
    #   greeter.enable = true;
    # };

    libinput = {
      enable = true;
      # disable mouse acceleration
      #mouse.accelProfile = "flat";
      # mouse.accelSpeed = "0.5";
      touchpad.accelSpeed = "0.4";
      mouse.middleEmulation = false;
    };
  };

  # fprint
  # services.fprintd.enable = true;
  services.xserver.displayManager.sessionPackages = [ pkgs.river ];
  services.xserver.videoDrivers = [ "amdgpu" ];

  services.gnome.tracker.enable = false;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;
  # resolve gnome and plasma issues
  programs.ssh.askPassword = pkgs.lib.mkForce "${pkgs.x11_ssh_askpass}/libexec/x11-ssh-askpass";

 
}
