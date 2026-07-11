{
  config,
  pkgs,
  inputs,
  pkgs-master,
  lib,
  ...
}:
{
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      libvdpau-va-gl
      libva
      libva-vdpau-driver
      # rocmPackages.clr.icd
      # rocmPackages.clr
    ];
    # For 32 bit applications
    extraPackages32 = with pkgs.driversi686Linux; [
      libvdpau-va-gl
      libva-vdpau-driver
    ];
    enable32Bit = true;
  };

  # video driver — moved from gui.nix to avoid conflict with nvidia on nixos-work
  services.xserver.videoDrivers = [ "amdgpu" ];

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "radeonsi";
    VDPAU_DRIVER = "radeonsi";
    # MOZ_DISABLE_RDD_SANDBOX="1";
    AMD_VULKAN_ICD = "RADV";
    # Don't pin VK_ICD_FILENAMES to the 64-bit ICD — it starves 32-bit apps
    # (Steam client) of a usable ICD and breaks their Vulkan init. Let the
    # loader auto-discover both /run/opengl-driver{,-32} ICDs.
    # MOZ_ENABLE_WAYLAND="1";
  };

  # hardware.amdgpu.opencl.enable = true;
}
