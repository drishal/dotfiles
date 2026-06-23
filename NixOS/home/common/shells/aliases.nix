{ config, pkgs, ... }:

{
  # 2. The Aliases (Apply to ALL shells: Fish, Zsh, Bash, etc.)
  home.shellAliases = {
    # --- System ---
    nix-config = "sudo vim /etc/nixos/configuration.nix";
    sudo = "sudo "; # Allows aliases to work with sudo

    # --- Nix / Home Manager ---
    nfu = "nix flake update --flake ~/dotfiles";
    nrs = "sudo nixos-rebuild switch --flake ~/dotfiles -L";
    nrb = "sudo nixos-rebuild boot --flake ~/dotfiles -L";
    nrsi = "sudo nixos-rebuild switch --flake --impure ~/dotfiles -L";
    hms = "home-manager switch --flake ~/dotfiles";
    hms-offline = "home-manager switch --flake ~/dotfiles --option substitute false";
    home-setup = "~/dotfiles/scripts/home-setup.sh";

    # --- Package Management ---
    yay = "paru";
    p = "paru";
    apt = "sudo nala";

    # --- Listing (ls/eza) ---
    ls = "eza --icons --group-directories-first";
    ll = "ls -l";
    lh = "ls -lh";
    la = "ls -la";
    lah = "ls -lah";
    l = "ls -lah";

    # --- Editors ---
    v = "nvim";
    h = "hx";
    edd = "emacs --daemon";
    e = "emacsclient -nw";

    # --- Hardware / Power ---
    b = "brightnessctl";
    bs = "brightnessctl s";
    energy_now = "cat /sys/class/power_supply/BAT0/energy_now";
    touchpad-fix = "sudo modprobe -r i8042; sudo modprobe i8042";

    # Power Profiles
    power_performance = "sudo echo 'performance' | sudo tee /sys/firmware/acpi/platform_profile";
    power_bal = "sudo echo 'balanced' | sudo tee /sys/firmware/acpi/platform_profile; sudo cpupower frequency-set -g schedutil";
    power_saver = "sudo echo 'low-power' | sudo tee /sys/firmware/acpi/platform_profile; sudo cpupower frequency-set -g schedutil";
    power_now = "cat /sys/firmware/acpi/platform_profile";
    amdgpu_high = "echo 'high' > /sys/class/drm/card0/device/power_dpm_force_performance_level";

    # TT Scheduler
    tt_balancer_normal = "sudo sysctl -w kernel.sched_tt_balancer_opt=0";
    tt_balancer_candidate = "sudo sysctl -w kernel.sched_tt_balancer_opt=1";
    tt_balancer_cfs = "sudo sysctl -w kernel.sched_tt_balancer_opt=2";
    tt_balancer_ps = "sudo sysctl -w kernel.sched_tt_balancer_opt=3";

    # --- Gaming ---
    xon = "steam-run ~/Desktop/games/Xonotic/xonotic-linux-sdl.sh";
    xon-glx = "~/Desktop/games/Xonotic/xonotic-linux-glx.sh";
    stk = "~/Desktop/games/SuperTuxKart-1.2-linux/run_game.sh";

    # --- Utilities ---
    wayland-screenshot = "grimshot copy output";
    wayland-screenshot-area = "grimshot copy area";
    whoogle = "docker run --publish 5000:5000 --detach benbusby/whoogle-search:latest";
    set-wall = "feh --bg-scale";
    push-all = "~/dotfiles/scripts/push-all.sh";
    galaxy-buds = "steam-run ~/Downloads/GalaxyBudsClient_Linux_64bit_Portable.bin";
    remove-dunst = "sudo rm /usr/share/dbus-1/services/org.knopwob.dunst.service";
    mongodb = "sudo systemctl start mongodb.service";
    wine64 = "env WINEARCH=win64 WINEPREFIX='/home/drishal/.wine64' wine64";

    # --- Tools ---
    # watch-amd-gpu = "sudo watch -n 0.5 bat /sys/kernel/debug/dri/0/amdgpu_pm_info";
    youtube-dl = "yt-dlp";
    yt-dlp-mp3 = "yt-dlp --no-playlist -x --audio-format=mp3 -f bestaudio";
    repo-sync = "repo sync -c --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j$(nproc --all);";
    sleep-check = "journalctl -u systemd-suspend.service | tail";
    upload = "curl -sL https://git.io/file-transfer | sh && ./transfer wet";

    # --- Virtualization / Containers ---
    fedora-distrobox = "distrobox-enter fedora-toolbox-35";
    arch-distrobox = "distrobox-enter Arch";

    # Bedrock (Strat)
    bed-ubuntu = "strat -r tut-ubuntu bash";
    bed-arch = "strat -r arch zsh";
    bed-alpine = "strat -r alpine bash";
    bed-void = "strat -r tut-void bash";

    # Waydroid
    waydroid-start = "waydroid session start; rm ~/.local/share/applications/waydroid*";
    waydroid-ui = "waydroid show-full-ui; rm ~/.local/share/applications/waydroid*";

    # Warp
    wcon = "warp-cli connect";
    wdis = "warp-cli disconnect";

    # Hyprland
    laptop-disable = "hyprctl keyword monitor eDP-1, disable";

    # Misc
    qemu-create-img = "qemu-img create -f qcow2";
    arch = "OVERFS_MODE=1 /home/drishal/Desktop/iso/arch/runimage.superlite --run-shell";
  };
  home.packages = with pkgs; [
    (pkgs.writeShellScriptBin "watch-sync" ''
      export WATCH_SYNC_BASE00="#${config.lib.stylix.colors.base00}"
      export WATCH_SYNC_BASE01="#${config.lib.stylix.colors.base01}"
      export WATCH_SYNC_BASE02="#${config.lib.stylix.colors.base02}"
      export WATCH_SYNC_BASE03="#${config.lib.stylix.colors.base03}"
      export WATCH_SYNC_BASE05="#${config.lib.stylix.colors.base05}"
      export WATCH_SYNC_BASE08="#${config.lib.stylix.colors.base08}"
      export WATCH_SYNC_BASE0A="#${config.lib.stylix.colors.base0A}"
      export WATCH_SYNC_BASE0B="#${config.lib.stylix.colors.base0B}"
      export WATCH_SYNC_BASE0C="#${config.lib.stylix.colors.base0C}"
      export WATCH_SYNC_BASE0D="#${config.lib.stylix.colors.base0D}"
      exec ${pkgs.python3.withPackages (ps: [ ps.rich ps.textual ])}/bin/python ${../../../../scripts/watch-sync.py} "$@"
    '')
    (pkgs.writeShellScriptBin "watch-gpu" ''
      export PATH="${pkgs.fzf}/bin:${pkgs.findutils}/bin:${pkgs.coreutils}/bin:$PATH"
      export WATCH_GPU_BASE00="#${config.lib.stylix.colors.base00}"
      export WATCH_GPU_BASE01="#${config.lib.stylix.colors.base01}"
      export WATCH_GPU_BASE02="#${config.lib.stylix.colors.base02}"
      export WATCH_GPU_BASE03="#${config.lib.stylix.colors.base03}"
      export WATCH_GPU_BASE05="#${config.lib.stylix.colors.base05}"
      export WATCH_GPU_BASE08="#${config.lib.stylix.colors.base08}"
      export WATCH_GPU_BASE0A="#${config.lib.stylix.colors.base0A}"
      export WATCH_GPU_BASE0B="#${config.lib.stylix.colors.base0B}"
      export WATCH_GPU_BASE0C="#${config.lib.stylix.colors.base0C}"
      export WATCH_GPU_BASE0D="#${config.lib.stylix.colors.base0D}"
      exec ${pkgs.python3.withPackages (ps: [ ps.rich ps.textual ])}/bin/python ${../../../../scripts/watch-gpu.py} "$@"
    '')
    (pkgs.writeShellScriptBin "devenv-envrc" ''
      install -m 755 ${pkgs.writeText "devenv-envrc-template" ''
        #!/usr/bin/env bash

        eval "$(devenv direnvrc)"

        # You can pass flags to the devenv command
        # For example: use devenv --impure --option services.postgres.enable:bool true
        use devenv
      ''} .envrc

      echo "created .envrc"
    '')
  ];
}
