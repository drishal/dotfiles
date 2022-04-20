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

  # overlays

  nixpkgs.overlays = [
    #suckless overlays
    (final: prev: {
      dwm = prev.dwm.overrideAttrs (old: { src = ../suckless/dwm-6.3; });
      dwmblocks = prev.dwmblocks.override (old: {
        # src = ../suckless/dwmblocks
        conf = ../suckless/dwmblocks/blocks.def.h;
      });
    })

    # river desktop session
    (final: prev: {
      inherit (prev) callPackage fetchFromGitHub;

      river =
        let
          riverSession = ''
            [Desktop Entry]
            Name=River
            Comment=Dynamic Wayland compositor
            Exec=river
            Type=Application
          '';
        in
        prev.river.overrideAttrs (prevAttrs: rec {
          postInstall = ''
            mkdir -p $out/share/wayland-sessions
            echo "${riverSession}" > $out/share/wayland-sessions/river.desktop
          '';
          passthru.providedSessions = [ "river" ];
        });
    })

    # picom
    (self: super:
      {
        picom = super.picom.overrideAttrs (_: {
          src = builtins.fetchTarball {
            url = https://github.com/yshui/picom/archive/refs/heads/next.zip;
            #sha256 = lib.fakeSha256;
            sha256 = "sha256:0lh3p3lkafkb2f0vqd5d99xr4wi47sgb57x65wa2cika8pz5sikv";
          };
        });
      })
  ];

}
