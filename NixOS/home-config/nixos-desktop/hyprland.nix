{ config, lib, pkgs, ... }:
let
  hyprPackage = config.wayland.windowManager.hyprland.package;
  acer4kMode = "3840x2160@160";
  acerPerfMode = "1920x1080@320";
  lgMode = "1920x1080@143.98";
  monitorStateFile = "$HOME/.local/state/hypr-monitor-profile";
  hyprMonitorToggle = pkgs.writeShellScriptBin "hypr-monitor-toggle" ''
    #!/usr/bin/env bash
    set -eu

    mkdir -p "$HOME/.local/state"

    current_mode="$(${hyprPackage}/bin/hyprctl monitors | ${pkgs.gawk}/bin/awk '
      /^Monitor DP-1 / {
        getline
        if (match($0, /[0-9]+x[0-9]+@[0-9.]+/)) {
          print substr($0, RSTART, RLENGTH)
        }
        exit
      }
    ')"

    if [[ "$current_mode" == "${acer4kMode}"* ]]; then
      ${hyprPackage}/bin/hyprctl keyword monitor "DP-1, ${acerPerfMode}, 0x0, 1"
      ${hyprPackage}/bin/hyprctl keyword monitor "DP-2, ${lgMode}, 1920x0, 1, transform, 1"
      printf '%s\n' perf > ${monitorStateFile}
    else
      ${hyprPackage}/bin/hyprctl keyword monitor "DP-1, ${acer4kMode}, 0x0, 1.5"
      ${hyprPackage}/bin/hyprctl keyword monitor "DP-2, ${lgMode}, 2560x0, 1, transform, 1"
      printf '%s\n' 4k > ${monitorStateFile}
    fi
  '';
  hyprApplyMonitorProfile = pkgs.writeShellScriptBin "hypr-apply-monitor-profile" ''
    #!/usr/bin/env bash
    set -eu

    profile="4k"
    if [[ -f ${monitorStateFile} ]]; then
      profile="$(cat ${monitorStateFile})"
    fi

    if [[ "$profile" == "perf" ]]; then
      ${hyprPackage}/bin/hyprctl keyword monitor "DP-1, ${acerPerfMode}, 0x0, 1"
      ${hyprPackage}/bin/hyprctl keyword monitor "DP-2, ${lgMode}, 1920x0, 1, transform, 1"
    else
      ${hyprPackage}/bin/hyprctl keyword monitor "DP-1, ${acer4kMode}, 0x0, 1.5"
      ${hyprPackage}/bin/hyprctl keyword monitor "DP-2, ${lgMode}, 2560x0, 1, transform, 1"
    fi
  '';
  hyprRestartDms = pkgs.writeShellScriptBin "hypr-restart-dms" ''
    #!/usr/bin/env bash
    set -eu

    pkill dms || true
    dms run
    sleep 1
    hypr-apply-monitor-profile
  '';
in
{
  home.packages = [
    hyprMonitorToggle
    hyprApplyMonitorProfile
    hyprRestartDms
  ];

  wayland.windowManager.hyprland.settings = {
    monitor = [
      "DP-1, ${acer4kMode}, 0x0, 1.5"
      "DP-2, ${lgMode}, 2560x0, 1, transform, 1"
    ];

    workspace = [
      "1, monitor:DP-1"
      "2, monitor:DP-1"
      "3, monitor:DP-1"
      "4, monitor:DP-1"
      "5, monitor:DP-1"
      "6, monitor:DP-2"
      "7, monitor:DP-2"
      "8, monitor:DP-2"
      "9, monitor:DP-2"
      "10, monitor:DP-2"
    ];

    cursor = {
      no_hardware_cursors = true;
    };
  };

  wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
    unbind = $mainMod, x
    unbind = $mainMod SHIFT, M
    bind = $mainMod, x, exec, hypr-restart-dms
    bind = $mainMod SHIFT, M, exec, hypr-monitor-toggle
  '';
}
