{ config, pkgs, inputs, lib, ... }:
{
  imports =
    [
      ./hardware-configuration.nix
      ./system/imports.nix
    ];
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

    # dwmblocks 
    #    (self: super: {
    #      dwmblocks = super.callPackage ./packages/dwmblocks/dwmblocks.nix {};
    #      conf = ../suckless/dwmblocks/blocks.def.h;
    #    })
    #
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

    # xmonad 
    #    (final: prev: {
    #      haskellPackages = prev.haskellPackages.override (old: {
    #        overrides = self: super: {
    #          xmonad = prev.haskellPackages.xmonad_0_17_0;
    #          xmonad-contrib = prev.haskellPackages.xmonad-contrib_0_17_0;
    #          xmonad-extras = prev.haskellPackages.xmonad-extras_0_17_0;
    #        };
    #      });
    #    })
    #
    # batdistrack
    # (self: super: {
    #   batdistrack = super.callPackage ./packages/batdistrack/default.nix {};
    # })
    # # (final: prev: {
    #   picom = prev.picom.overrideAttrs (old: { src = /home/drishal/Desktop/git-stuff/picom;});
    # })

    # (self: super: {
    #   discord = super.discord.overrideAttrs (_:{
    #    builtins.fetchTarball { src="https://discord.com/api/download?platform=linux&format=tar.gz"; sha256 = lib.fakeSha256;};
    # });
    #})
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
  system.stateVersion = "21.05";

}

