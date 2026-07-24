{ pkgs, ... }:

# Single derivation built from config.org, shared between home.packages and
# the systemd user daemon.
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
      # projectile byte-compiles a hard (require 'consult) without declaring the
      # dep; drop once emacs-overlay #544 is fixed.
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

  # Supervised daemon instead of a fire-and-forget `emacs --daemon` autostart.
  # "graphical" orders it after graphical-session.target so pgtk inherits WAYLAND_DISPLAY.
  services.emacs = {
    enable = true;
    package = myEmacs;
    startWithUserSession = "graphical";
  };
}
