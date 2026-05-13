{
  config,
  pkgs,
  ...
}:

let
  # Sway uses connector names (e.g. DP-1, HDMI-A-1) not descriptions like Hyprland.
  # Find yours with: swaymsg -t get_outputs
  # Update these to match your actual connector names.
  acerOutput = "DP-1";
  lgOutput = "DP-2";

  # Monitor toggle script (ported from hypr-monitor-toggle)
  swayMonitorToggle = pkgs.writeShellScriptBin "sway-monitor-toggle" ''
    #!/usr/bin/env bash
    set -eu

    mkdir -p "$HOME/.local/state"

    current_mode="$(swaymsg -t get_outputs | ${pkgs.jq}/bin/jq -r "
      .[] | select(.name == \"${acerOutput}\") | .current_mode.width, .current_mode.height
    " | tr '\n' 'x' | sed 's/x$//')"

    if [[ "$current_mode" == "3840x2160"* ]]; then
      swaymsg output "${acerOutput}" mode 1920x1080@320Hz pos 0 0 scale 1
      swaymsg output "${lgOutput}" mode 1920x1080@144Hz pos 1920 0 scale 1 transform 90
      printf '%s\n' perf > "$HOME/.local/state/sway-monitor-profile"
    else
      swaymsg output "${acerOutput}" mode 3840x2160@160Hz pos 0 0 scale 1.5
      swaymsg output "${lgOutput}" mode 1920x1080@144Hz pos 2560 0 scale 1 transform 90
      printf '%s\n' 4k > "$HOME/.local/state/sway-monitor-profile"
    fi
  '';

  swayApplyMonitorProfile = pkgs.writeShellScriptBin "sway-apply-monitor-profile" ''
    #!/usr/bin/env bash
    set -eu

    profile="4k"
    if [[ -f "$HOME/.local/state/sway-monitor-profile" ]]; then
      profile="$(cat "$HOME/.local/state/sway-monitor-profile")"
    fi

    if [[ "$profile" == "perf" ]]; then
      swaymsg output "${acerOutput}" mode 1920x1080@320Hz pos 0 0 scale 1
      swaymsg output "${lgOutput}" mode 1920x1080@144Hz pos 1920 0 scale 1 transform 90
    else
      swaymsg output "${acerOutput}" mode 3840x2160@160Hz pos 0 0 scale 1.5
      swaymsg output "${lgOutput}" mode 1920x1080@144Hz pos 2560 0 scale 1 transform 90
    fi
  '';

  swayRestartDms = pkgs.writeShellScriptBin "sway-restart-dms" ''
    #!/usr/bin/env bash
    set -eu

    pkill dms || true
    dms run
    sleep 1
    sway-apply-monitor-profile
  '';
in
{
  home.packages = [
    swayMonitorToggle
    swayApplyMonitorProfile
    swayRestartDms
  ];

  wayland.windowManager.sway.config = {
    # --- Output/Monitor config (default: 4K mode) ---
    # Sway uses connector names, not descriptions. Find yours with:
    #   swaymsg -t get_outputs
    output = {
      "${acerOutput}" = {
        mode = "3840x2160@160Hz";
        pos = "0 0";
        scale = "1.5";
      };
      "${lgOutput}" = {
        mode = "1920x1080@144Hz";
        pos = "2560 0";
        scale = "1";
        transform = "90";
      };
    };

    # --- Workspace → output assignments ---
    workspaceOutputAssign = [
      { workspace = "1"; output = acerOutput; }
      { workspace = "2"; output = acerOutput; }
      { workspace = "3"; output = acerOutput; }
      { workspace = "4"; output = acerOutput; }
      { workspace = "5"; output = acerOutput; }
      { workspace = "6"; output = lgOutput; }
      { workspace = "7"; output = lgOutput; }
      { workspace = "8"; output = lgOutput; }
      { workspace = "9"; output = lgOutput; }
      { workspace = "10"; output = lgOutput; }
    ];
  };

  # Override keybinds from main sway.nix for desktop-specific actions
  wayland.windowManager.sway.config.keybindings =
    let
      mod = config.wayland.windowManager.sway.config.modifier;
    in
    {
      "${mod}+x" = "exec sway-restart-dms";
      "${mod}+Shift+m" = "exec sway-monitor-toggle";
    };
}
