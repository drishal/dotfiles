{ config, pkgs, inputs, lib, ... }:

{
  nix = {
    # trustedUsers = [ "root" "drishal" ];
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
      # extra-sandbox-paths = /nix/var/cache/ccache
    '';
    # settings.trusted-substituters = ["s3://nix-cache"];
    settings = {
      auto-optimise-store = true;
      trusted-users = [ "root" "drishal" ];
    };
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "steam"
    "steam-original"
    "steam-runtime"
  ];
  hardware.enableRedistributableFirmware = true;
}
