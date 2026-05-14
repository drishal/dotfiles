{ pkgs, ... }:

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
    watch-sync = "watch -d grep -e Dirty: -e Writeback: /proc/meminfo";
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
    (pkgs.writeShellScriptBin "watch-gpu" ''
      export PATH="${pkgs.fzf}/bin:${pkgs.bat}/bin:${pkgs.findutils}/bin:${pkgs.gnugrep}/bin:$PATH"

      detect_gpu() {
        # Check for AMD first (has amdgpu_pm_info in debugfs)
        AMD_GPUS=$(sudo find /sys/kernel/debug/dri -maxdepth 2 -name amdgpu_pm_info 2>/dev/null | head -1)
        if [ -n "$AMD_GPUS" ]; then
          echo "amd"
          return
        fi

        # Check for NVIDIA via nvidia-smi
        if command -v nvidia-smi &>/dev/null && nvidia-smi -L &>/dev/null; then
          echo "nvidia"
          return
        fi

        echo "unknown"
      }

      watch_amd() {
        GPUS=$(sudo find /sys/kernel/debug/dri -maxdepth 2 -name amdgpu_pm_info 2>/dev/null | awk -F/ '{print $(NF-1)}')

        if [ -z "$GPUS" ]; then
          echo "No AMD GPUs found in /sys/kernel/debug/dri."
          exit 1
        fi

        SELECTED_ID=$(echo "$GPUS" | fzf \
          --prompt="Select GPU > " \
          --header="Found AMD GPUs at /sys/kernel/debug/dri/" \
          --height=40% \
          --layout=reverse \
          --border \
          --preview="sudo cat /sys/kernel/debug/dri/{}/amdgpu_pm_info" \
          --preview-window=right:60%)

        if [ -n "$SELECTED_ID" ]; then
          sudo watch -n 0.5 "bat --style=plain --paging=never --color=always /sys/kernel/debug/dri/$SELECTED_ID/amdgpu_pm_info"
        fi
      }

      watch_nvidia() {
        GPU_COUNT=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | wc -l)
        if [ "$GPU_COUNT" -eq 0 ]; then
          echo "No NVIDIA GPUs found."
          exit 1
        fi

        if [ "$GPU_COUNT" -gt 1 ]; then
          SELECTED_GPU=$(nvidia-smi --query-gpu=index,name --format=csv,noheader 2>/dev/null | fzf \
            --prompt="Select GPU > " \
            --header="Found NVIDIA GPUs" \
            --height=40% \
            --layout=reverse \
            --border \
            --preview="idx=\$(echo {} | cut -d, -f1 | tr -d ' '); nvidia-smi --query-gpu=index,name,utilization.gpu,utilization.memory,temperature.gpu,power.draw,clocks.current.sm,clocks.current.memory,memory.used,memory.total --format=csv -i \$idx" \
            --preview-window=right:60% | cut -d, -f1 | tr -d ' ')
        else
          SELECTED_GPU=0
        fi

        watch -n 1 "nvidia-smi --query-gpu=timestamp,name,utilization.gpu,utilization.memory,temperature.gpu,power.draw,clocks.current.sm,clocks.current.memory,memory.used,memory.total,pstate --format=csv -i $SELECTED_GPU"
      }

      GPU_TYPE=$(detect_gpu)

      case "$GPU_TYPE" in
        amd)
          echo "Detected AMD GPU"
          watch_amd
          ;;
        nvidia)
          echo "Detected NVIDIA GPU"
          watch_nvidia
          ;;
        *)
          echo "No supported GPU detected (need AMD with amdgpu or NVIDIA with nvidia-smi)."
          exit 1
          ;;
      esac
    '')
  ];
}
