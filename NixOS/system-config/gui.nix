{ config, pkgs, inputs, lib, ... }:

{
  services.xserver = {
    enable = true;

    videoDrivers = [ "amdgpu" ];

    # window wmanagers
    windowManager = {
      qtile.enable = true;

      xmonad = {
        enable = true;
        enableContribAndExtras = true;
      };

      dwm.enable = true;

      leftwm.enable = true;
      awesome = {
        enable = true;
        luaModules = with pkgs.luaPackages; [
          luarocks # is the package manager for Lua modules
          luadbi-mysql # Database abstraction layer
        ];

      };
      # awesome.enable = true;
    };

    # Desktop Environment
    desktopManager = {
      plasma5.enable = true;
      # xfce.enable = true;
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
  # QT_QPA_PLATFORMTHEME
  environment.variables.QT_QPA_PLATFORMTHEME = lib.mkForce "";
  # river 
  services.xserver.displayManager.sessionPackages = [
    (pkgs.river.overrideAttrs
      (prevAttrs: rec {
        postInstall =
          let
            riverSession = ''
              [Desktop Entry]
              Name=River
              Comment=Dynamic Wayland compositor
              Exec=river
              Type=Application
            '';
          in
          ''
            mkdir -p $out/share/wayland-sessions
            echo "${riverSession}" > $out/share/wayland-sessions/river.desktop
          '';
        passthru.providedSessions = [ "river" ];
      })
    )
  ];

  # services.gnome.tracker.enable = false;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;
  # resolve gnome and plasma issues
  programs.ssh.askPassword = pkgs.lib.mkForce "${pkgs.x11_ssh_askpass}/libexec/x11-ssh-askpass";

  # lidswitch
  services.logind.lidSwitch = "suspend";
  #some overlays
  nixpkgs.overlays = [
    #suckless overlays
    (final: prev: {
      dwm = prev.dwm.overrideAttrs (old: { src = ../../suckless/dwm-6.3; });
      dwmblocks = prev.dwmblocks.override (old: {
        conf = ../../suckless/dwmblocks/blocks.def.h;
      });
    })
  ];
}
