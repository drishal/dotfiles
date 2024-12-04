# GPU (Nvidia) Configuration
#- <https://wiki.nixos.org/wiki/Nvidia>
#- <https://wiki.hyprland.org/Nvidia>
{
  pkgs,
  config,
  ...
}:
{
  # nvidia is the proprietary driver for Nvidia GPUs
  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  boot = {
    kernelModules = [
      "nvidia"
      "nvidia_modeset"
      "nvidia_uvm"
      "nvidia_drm"
      "i2c-nvidia_gpu"
    ];
    blacklistedKernelModules = [ "nouveau" ];
    kernelParams = ["nvidia-drm.fbdev=1" "nvidia_drm.modeset=1"];

    extraModprobeConfig = ''
      blacklist nouveau
      options nouveau modeset=0
    '';
  };

  hardware = {
    nvidia = {
      #- <https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/os-specific/linux/nvidia-x11/default.nix>
      # package = config.boot.kernelPackages.nvidiaPackages.stable;
      package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
        version = "565.57.01";
        sha256_64bit = "sha256-buvpTlheOF6IBPWnQVLfQUiHv4GcwhvZW3Ks0PsYLHo=";
        sha256_aarch64 = "sha256-buvpTlheOF6IBPWnQVLfQUiHv4GcwhvZW3Ks0PsYLHo=";
        openSha256 = "sha256-/tM3n9huz1MTE6KKtTCBglBMBGGL/GOHi5ZSUag4zXA=";
        settingsSha256 = "sha256-kQsvDgnxis9ANFmwIwB7HX5MkIAcpEEAHc8IBOLdXvk=";
        persistencedSha256 = "sha256-hdszsACWNqkCh8G4VBNitDT85gk9gJe1BlQ8LdrYIkg=";
        patchesOpen = [
          ./nvidia.patch
        ];
      };

      # package = pkgs.linuxPackages_latest.nvidiaPackages.beta;

      # Required
      modesetting.enable = true;

      # Experimental, and can cause sleep/suspend to fail
      powerManagement.enable = false;

      # Experimental and only works on modern Nvidia GPUs (Turing or newer)
      powerManagement.finegrained = false;
      nvidiaSettings = true; # GUI settings application, accessible via `nvidia-settings`

      # Nvidia open source kernel module (not to be confused with the
      # independent third-party "nouveau" open source driver)
      open = false;

      # Ensure all GPUs stay awake even during headless mode
      # Fixes a glitch
      nvidiaPersistenced = true;
    };

    # Required for Nvidia support in containers (Docker, Podman, etc.)
    nvidia-container-toolkit = {
      enable = true;
      mount-nvidia-executables = true;
      mount-nvidia-docker-1-directories = true;
    };

    # <https://wiki.nixos.org/wiki/Nvidia#Laptop_configuration:_hybrid_graphics_(Optimus_PRIME)>
    /*
      nvidia.prime = {
        sync.enable = true;

        offload = {
          enable = true;
          enableOffloadCmd = true;
        };

        # Find IDs using: `sudo lshw -c display`
        # intelBusId = "PCI:0:2:0";
        # nvidiaBusId = "PCI:14:0:0";
        # amdgpuBusId = "PCI:54:0:0";
      };
    */
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  hardware.graphics.extraPackages = with pkgs; [
    vaapiVdpau
    nvidia-vaapi-driver
  ];
}
