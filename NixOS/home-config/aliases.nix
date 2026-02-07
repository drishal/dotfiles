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
    perf = "sudo echo 'performance' | sudo tee /sys/firmware/acpi/platform_profile";
    bal = "sudo echo 'balanced' | sudo tee /sys/firmware/acpi/platform_profile; sudo cpupower frequency-set -g schedutil";
    ps = "sudo echo 'low-power' | sudo tee /sys/firmware/acpi/platform_profile; sudo cpupower frequency-set -g schedutil";
    pnow = "cat /sys/firmware/acpi/platform_profile";
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
    (pkgs.writeShellScriptBin "watch-amd-gpu" ''
      # 1. Force path to include necessary tools
    export PATH="${pkgs.fzf}/bin:${pkgs.bat}/bin:${pkgs.findutils}/bin:$PATH"

    # 2. Find valid AMD GPUs (Checking for existence of 'amdgpu_pm_info')
    # We use sudo here because /sys/kernel/debug is root-only
    echo "sudo: Scanning debugfs for AMD GPUs..."
    
    # This finds files like /sys/kernel/debug/dri/0/amdgpu_pm_info and extracts the ID "0"
    GPUS=$(sudo find /sys/kernel/debug/dri -maxdepth 2 -name amdgpu_pm_info 2>/dev/null | awk -F/ '{print $(NF-1)}')

    if [ -z "$GPUS" ]; then
      echo "No AMD GPUs found in /sys/kernel/debug/dri."
      exit 1
    fi

    # 3. FZF Selection with Live Preview
    # We pass the ID to fzf, and the preview window cat's the file so you know which card is which
    SELECTED_ID=$(echo "$GPUS" | fzf \
      --prompt="Select GPU > " \
      --header="Found AMD GPUs at /sys/kernel/debug/dri/" \
      --height=40% \
      --layout=reverse \
      --border \
      --preview="sudo cat /sys/kernel/debug/dri/{}/amdgpu_pm_info" \
      --preview-window=right:60%)

    # 4. If user selected something, run the watch command
    if [ -n "$SELECTED_ID" ]; then
      # --color=always forces bat to output colors even inside 'watch'
      sudo watch -n 0.5 "bat --style=plain --paging=never --color=always /sys/kernel/debug/dri/$SELECTED_ID/amdgpu_pm_info"
    fi
    '')
  ];
}
