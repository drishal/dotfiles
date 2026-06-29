{ pkgs, ... }:

# Emacs: a single derivation (myEmacs) built from the literate config.org via
# emacsWithPackagesFromUsePackage, shared between home.packages (binaries on
# PATH) and the systemd user daemon (services.emacs).
let
  myEmacs = pkgs.emacsWithPackagesFromUsePackage {
    config = ../../../../emacs/config.org;
    package = pkgs.emacs-unstable-pgtk;
    alwaysEnsure = true;
    alwaysTangle = true;
    extraEmacsPackages =
      epkgs: with epkgs; [
        use-package
        treesit-grammars.with-all-grammars
        vterm
      ];
    override = final: prev: {
      rustic = prev.rustic.overrideAttrs { ignoreCompilationError = true; };
      # projectile 20260627.907 added projectile-consult.el with a hard
      # (require 'consult) at byte-compile time, but consult isn't a declared
      # compile dep. Drop this once emacs-overlay #544 is fixed upstream.
      projectile = prev.projectile.overrideAttrs { ignoreCompilationError = true; };
      eglot-booster = final.melpaBuild {
        pname = "eglot-booster";
        version = "0.1.0.0.20240616";
        src = pkgs.fetchFromGitHub {
          owner = "jdtsmith";
          repo = "eglot-booster";
          rev = "cab7803c4f0adc7fff9da6680f90110674bb7a22";
          hash = "sha256-xUBQrQpw+JZxcqT1fy/8C2tjKwa7sLFHXamBm45Fa4Y=";
        };
      };
    };
  };
in
{
  home.packages = [ myEmacs ];

  # Run the daemon as a supervised systemd user service (restart-on-failure +
  # journald logs), replacing the fire-and-forget `emacs --daemon` autostart.
  # startWithUserSession = "graphical": ordered after graphical-session.target
  # so the pgtk daemon inherits WAYLAND_DISPLAY (imported by the compositor's
  # `dbus-update-activation-environment --systemd ...` line).
  services.emacs = {
    enable = true;
    package = myEmacs;
    startWithUserSession = "graphical";
  };
}
