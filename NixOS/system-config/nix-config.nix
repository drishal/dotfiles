{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  nix = {
    # trustedUsers = [ "root" "drishal" ];
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes auto-allocate-uids
      max-substitution-jobs = 64
      http-connections = 64
      auto-allocate-uids = true
      # configurable-impure-env = true
      # extra-sandbox-paths = /nix/var/cache/ccache
    '';
    # settings.trusted-substituters = ["s3://nix-cache"];
    settings = {
      auto-optimise-store = true;
      trusted-users = [
        "root"
        "drishal"
      ];
      substituters = [ "https://hyprland.cachix.org" ];
      #"https://emacsng.cachix.org"];
      trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
      #"emacsng.cachix.org-1:i7wOr4YpdRpWWtShI8bT6V7lOTnPeI7Ho6HaZegFWMI=" ]
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 3d";
    };
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "steam"
      "steam-original"
      "steam-runtime"
    ];
  nixpkgs.config.permittedInsecurePackages = [ "openssl-1.1.1t" ];
  hardware.enableRedistributableFirmware = true;
}
