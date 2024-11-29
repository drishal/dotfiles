{
  config,
  pkgs,
  inputs,
  pkgs-master,
  lib,
  ...
}:
{
  hardware.graphics =  {
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
  hardware.amdgpu.opencl.enable = true;
}
