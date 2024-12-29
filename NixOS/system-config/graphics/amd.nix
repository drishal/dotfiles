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
    ];
    # For 32 bit applications
    extraPackages32 = with pkgs.driversi686Linux; [
      libvdpau-va-gl
      libva-vdpau-driver
    ];
    enable32Bit = true;
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "radeonsi";
    VDPAU_DRIVER = "radeonsi";
    # MOZ_DISABLE_RDD_SANDBOX="1";
    # AMD_VULKAN_ICD = "RADV";
    # VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";
    # MOZ_ENABLE_WAYLAND="1";
  };

  # hardware.amdgpu.opencl.enable = true;
}
