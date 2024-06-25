{ config
, pkgs
, inputs
, lib
, ...
}:

{
  # displayManager.gdm.enable = true;
    # services.displayManager.sddm = {
    #   enable = true;
    #   wayland.enable = true;
    #   package = (pkgs.sddm.overrideAttrs (old: {
    #     patches = (old.patches or []) ++ [(pkgs.fetchpatch {
    #         url =
    #           "https://patch-diff.githubusercontent.com/raw/sddm/sddm/pull/1779.patch";
    #         sha256 = "sha256-8QP9Y8V9s8xrc+MIUlB7iHVNHbntGkw0O/N510gQ+bE=";
    #       })
    #     ];
    #   }));
    # };
  services.desktopManager = {
    plasma6 = {
      enable = true;
    };
  };

  services.libinput = {
    enable = true;
    # disable mouse acceleration
    #mouse.accelProfile = "flat";
    # mouse.accelSpeed = "0.5";
    touchpad.accelSpeed = "0.4";
    mouse.middleEmulation = false;
  };
  services.xserver = {
    enable = true;

    videoDrivers = [ "amdgpu" ];
    deviceSection = ''
      Option "DRI" "3"
    '';
    # window wmanagers
    windowManager = {
      qtile = {
        enable = true;
        # backend = "wayland";
        package = pkgs.qtile-module_git;
        extraPackages = _: [ pkgs.qtile-extras_git ];
      };

      xmonad = {
        enable = true;
        enableContribAndExtras = true;
      };

      dwm.enable = true;

      leftwm.enable = true;
      # awesome = {
      #   enable = true;
      #   luaModules = with pkgs.luaPackages; [
      #     luarocks # is the package manager for Lua modules
      #     luadbi-mysql # Database abstraction layer
      #   ];

      # };
      # awesome.enable = true;
    };

    # Desktop Environment
    desktopManager = {
      # plasma6.enable = true;
      #xfce.enable = true;
      # lxqt.enable = true;
      # gnome.enable = true;
    };
    # displayManager.lightdm.enable = false;
    # displayManager.lightdm = {
    #  enable = true;
    #  greeter.enable = true;
    # };

  };

  # services.greetd = {
  #   enable = true;
  #   settings = rec {
  #     initial_session = {
  #       command = "Hyprland";
  #       # command = "qtile start -b wayland";
  #       # command = "river";
  #       # command = "startplasma-wayland";
  #       user = "drishal";
  #     };
  #     default_session = initial_session;
  #   };
  # };
  # https://github.com/sjcobb2022/nixos-config/blob/main/hosts/common/optional/greetd.nix
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command =
          let
            session = config.services.displayManager.sessionData.desktops;
          in
            "${pkgs.greetd.tuigreet}/bin/tuigreet -t -s ${session}/share/xsessions:${session}/share/wayland-sessions";
      };
    };
  };
  # this is a life saver.
  # literally no documentation about this anywhere.
  # might be good to write about this...
  # https://www.reddit.com/r/NixOS/comments/u0cdpi/tuigreet_with_xmonad_how/
  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal"; # Without this errors will spam on screen
    TTYReset = true; # Without these bootlogs will spam on screen
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

  programs.hyprland = {
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    enable = true;
  };
  # QT settings
  # environment.variables.QT_QPA_PLATFORMTHEME = lib.mkForce "";
  # qt.platformTheme="qt5ct";
  environment.variables.QT_QPA_PLATFORMTHEME = lib.mkForce "kde";
  # qt.platformTheme="qt5ct";
  # environment.variables.QT_STYLE_OVERRIDE= lib.mkForce "";
  # river 
  services.displayManager.sessionPackages = [
    # (pkgs.river.overrideAttrs (prevAttrs: rec {
    #   postInstall =
    #     let
    #       riverSession = ''
    #         [Desktop Entry]
    #         Name=River
    #         Comment=Dynamic Wayland compositor
    #         Exec=river
    #         Type=Application
    #       '';
    #     in
    #     ''
    #       mkdir -p $out/share/wayland-sessions
    #       echo "${riverSession}" > $out/share/wayland-sessions/river.desktop
    #     '';
    #   passthru.providedSessions = [ "river" ];
    # }))

    #qtile wayland 
    # (pkgs.qtile_git.overrideAttrs
    #   (prevAttrs: rec {
    #     postInstall =
    #       let
    #         cfg = config.services.xserver.windowManager.qtile;
    #         pyEnv = pkgs.python3.withPackages (p: [ (cfg.package.unwrapped or cfg.package) ] ++ (cfg.extraPackages p));
    #         qtileSession = ''
    #           [Desktop Entry]
    #           Name=Qtile (wayland)
    #           Comment=Dynamic Wayland compositor
    #           Exec=${pkgs.writeShellScript "start-qtile" ''
    #                   exec ${pyEnv}/bin/qtile start -b ${cfg.backend} \
    #                   ${pkgs.lib.optionalString (cfg.configFile != null)
    #                     "--config \"${cfg.configFile}\""} "$@"
    #            ''}
    #           Type=Application
    #         '';
    #       in
    #         ''
    #         mkdir -p $out/share/wayland-sessions
    #         echo "${qtileSession}" > $out/share/wayland-sessions/qtile.desktop
    #       '';
    #     passthru.providedSessions = [ "qtile" ];
    #   })
    # )
  ];
  # chaotic.qtile.enable = true;
  services.gnome.tracker.enable = false;
  services.gnome.gnome-keyring.enable = true;
  environment.gnome.excludePackages = [
    pkgs.gnome-photos
    pkgs.gnome.gnome-software
    pkgs.gnome.geary
    pkgs.gnome.gnome-music
    pkgs.epiphany
  ];
  security.pam.services.sddm.enableGnomeKeyring = true;
  # resolve gnome and plasma issues
  programs.ssh.askPassword = pkgs.lib.mkForce "${pkgs.x11_ssh_askpass}/libexec/x11-ssh-askpass";

  # lidswitch
  services.logind = {
    lidSwitch = "suspend";
    extraConfig = "IdleAction=ignore";
  };

  # portal
  services.dbus.enable = true;
  # xdg.portal = {
  #   enable = true;
  #   wlr.enable = true;
  #   # kde.enable = false;
  #   extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  #   # gtkUsePortal = true;
  # };
  #some overlays
  nixpkgs.overlays = [
    #suckless overlays
    (final: prev: {
      dwm = prev.dwm.overrideAttrs (old: {
        src = ../../suckless/dwm-6.4;
      });
      dwmblocks = prev.dwmblocks.override (old: {
        conf = ../../suckless/dwmblocks/blocks.def.h;
      });
    })
    #     
    # (self: super:
    #   {
    #     tlp = super.tlp.overrideAttrs (_: {
    #       src = self.fetchFromGitHub {
    #         repo = "TLP";
    #         owner = "linrunner";
    #         rev = "f67faac1a0a7c82c9cee45c9ad8566f00bda28cc";
    #         sha256 = "sha256-VSj6VoTpLYm/nPAfIeOhoQ0Q1vmbsiLL+xFHzd/ngyk=";};
    #     });
    #   }) 
  ];
}
