{ config, pkgs, inputs, lib, ... }:
{
  #   boot.kernelPackages =
  #     let
  #       linux_custom_pkg = { fetchurl, buildLinux, ... } @ args:

  #         buildLinux (args // rec {
  #           version = "5.17.5";
  #           modDirVersion = version;

  #           src = fetchurl {
  #             url = "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-${version}.tar.xz";
  #             sha256 = "sha256-m7zRhblENvnI/pd/oOhi9g00ADViMn/OuyfJ+jQv6Yc=";
  #           };
  #           # kernelPatches = [ ];

  #           # extraConfig = ''
  #           #   AMD_PSTATE y
  #           # '';

  #           configfile = ./.config;

  #           extraMeta.branch = "5.17";
  #         } // (args.argsOverride or { }));
  #       linux_custom = pkgs.callPackage linux_custom_pkg { };
  #     in
  #     pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor linux_custom);
  #####################################
  boot.kernelPackages =
    let base_kernel = pkgs.linuxPackages_latest;
    in
    pkgs.linuxPackagesFor (pkgs.linuxKernel.manualConfig {
      inherit (pkgs) stdenv;
      inherit (pkgs) lib;
      # inherit (base_kernel) src;
      version = "5.17.5";
      src = pkgs.fetchurl {
        url = "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.17.5.tar.xz";
        sha256 = "sha256-m7zRhblENvnI/pd/oOhi9g00ADViMn/OuyfJ+jQv6Yc=";
      };

      configfile = ./.config;
      allowImportFromDerivation = true;
    }
    );
}
