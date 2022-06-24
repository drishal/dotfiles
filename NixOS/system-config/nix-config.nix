{ config, pkgs, inputs, lib, ... }:

{
  nix = {
    trustedUsers = [ "root" "drishal" ];
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
      # extra-sandbox-paths = /nix/var/cache/ccache
    '';
    # settings.trusted-substituters = ["s3://nix-cache"];
    settings.auto-optimise-store = true;
  };

  nixpkgs.config.allowUnfree = true;
  hardware.enableRedistributableFirmware = true;
}
