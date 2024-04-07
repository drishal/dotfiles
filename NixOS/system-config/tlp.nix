{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
{
  services.tlp = {
    enable = true;
    settings = {
      # platform profile
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";

      #usb autosuspend
      USB_AUTOSUSPEND = 0;

      #scaling
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "schedutil";

      #RADEON
      #RADEON_DPM_PERF_LEVEL_ON_AC="high";
      #RADEON_DPM_PERF_LEVEL_ON_BAT="auto";

      #RADEON_DPM_STATE_ON_AC="performance";
      #RADEON_DPM_STATE_ON_BAT="battery";

      #CPU_ENERGY_PERF_POLICY_ON_AC="performance";
      #CPU_ENERGY_PERF_POLICY_ON_BAT="balance_power";

      #cpu boost
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;
    };
  };
}
