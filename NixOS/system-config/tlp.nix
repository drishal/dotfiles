{ config, pkgs, inputs, lib, ... }:
{
  services.tlp = {
    enable=true;
    settings = {
      # platform profile
      PLATFORM_PROFILE_ON_AC="performance";
      PLATFORM_PROFILE_ON_BAT="balanced";

      #usb autosuspend
      USB_AUTOSUSPEND=0;

      #scaling
      CPU_SCALING_GOVERNOR_ON_AC="schedutil";
      CPU_SCALING_GOVERNOR_ON_BAT="schedutil";
    };
  };
}
