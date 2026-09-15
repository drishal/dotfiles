{ pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    go
    # (brave.overrideAttrs (old: {
    #   # brave is a plain derivation here (no .override); commandLineArgs is a
    #   # callPackage formal of make-brave.nix baked into the wrapper, so use overrideAttrs.
    #   commandLineArgs = (old.commandLineArgs or "") + " " + lib.concatStringsSep " " [
    #     # Wayland
    #     "--ozone-platform-hint=auto"
    #     "--enable-wayland-ime"
    #     # VA-API via nvidia-vaapi-driver (NVDEC backend)
    #     "--ignore-gpu-blocklist"
    #     "--enable-zero-copy"
    #     "--enable-features=VaapiVideoDecoder,VaapiIgnoreDriverChecks"
    #     "--disable-features=UseChromeOSDirectVideoDecoder"
    #     # GPU rasterization
    #     "--enable-gpu-rasterization"
    #     "--enable-native-gpu-memory-buffers"
    #     # NVIDIA Wayland
    #     "--enable-features=Vulkan"
    #     "--enable-hardware-overlays"
    #   ];
    # }))
  ];

  programs.brave-origin-beta = {
    enable = true;
    commandLineArgs = [
      "--ozone-platform-hint=auto"
      "--enable-wayland-ime"
      # VA-API via nvidia-vaapi-driver (NVDEC) — vainfo-verified.
      # No `Vulkan` feature here: ozone-wayland explicitly rejects it
      # ("not compatible with Vulkan"), and it was the crash suspect on 09/15.
      "--enable-features=AcceleratedVideoDecodeLinuxGL,VaapiVideoDecoder,VaapiIgnoreDriverChecks"
      "--disable-features=UseChromeOSDirectVideoDecoder"
      # No --use-angle=vulkan here: ANGLE-vulkan can't find libvulkan.so.1 on
      # Nix (not in the binary's RUNPATH), EGL init fails and GL falls back.
      # Default EGL/GL path verified error-free on the T400.
    ];
  };
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
  };
  # Service - WARNING: Open to public!
  services.vsftpd = {
    enable = true;
    writeEnable = true;
    localUsers = true;
    chrootlocalUser = true;
    allowWriteableChroot = true;
  };
  # services.postgresql = {
  #   enable = true;
  #   enableTCPIP = true;
  #   settings.port = 5433;
  #   authentication = pkgs.lib.mkOverride 10 ''
  #     local all all trust
  #     host all all 127.0.0.1/32 trust
  #     host all all ::1/128 trust
  #   '';
  #   initialScript = pkgs.writeText "backend-initScript" ''
  #     CREATE ROLE drishal WITH LOGIN PASSWORD 'aiphonepass' CREATEDB;
  #     CREATE DATABASE aiphone;
  #     GRANT ALL PRIVILEGES ON DATABASE aiphone TO drishal;
  #   '';
  # };
}
