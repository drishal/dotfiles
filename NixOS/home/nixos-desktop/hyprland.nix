{
  config,
  lib,
  pkgs,
  ...
}:
let
  hyprPackage = config.wayland.windowManager.hyprland.package;

  # ─── Monitor identifiers ────────────────────────────────────────────────
  acerMonitor = "desc:Acer Technologies XV272K V5 15391B0344201";
  lgMonitor = "desc:LG Electronics LG ULTRAGEAR 302NTUW8G822";
  acerDesc = "Acer Technologies XV272K V5 15391B0344201";

  # ─── Modes ──────────────────────────────────────────────────────────────
  acer4kMode = "3840x2160@160";
  acerPerfMode = "1920x1080@320";
  lgMode = "1920x1080@143.98";

  # ─── Color/HDR flags ────────────────────────────────────────────────────
  acer4kFlags = "bitdepth, 10, cm, srgb";
  acerPerfFlags = "bitdepth, 8, cm, srgb";

  # ─── State persistence ──────────────────────────────────────────────────
  monitorStateFile = "$HOME/.local/state/hypr-monitor-profile";
  monitorConfFile = "$HOME/.config/hypr/monitors.conf";

  # ─── Profile applier ───────────────────────────────────────────────────
  # Writes the active monitor layout to a sourced conf file so hyprctl reloads
  # (home-manager switch, manual reloads, etc.) don't clobber it, then applies
  # it immediately via hyprctl keyword for the live session.
  applyProfile = pkgs.writeShellScript "hypr-apply-profile-impl" ''
    #!/usr/bin/env bash
    set -eu

    profile="''${1:-4k}"

    case "$profile" in
      perf)
        acer_val="${acerMonitor}, ${acerPerfMode}, 0x0, 1, ${acerPerfFlags}"
        lg_val="${lgMonitor}, ${lgMode}, 1920x0, 1, transform, 1"
        ;;
      4k|*)
        acer_val="${acerMonitor}, ${acer4kMode}, 0x0, 1.5, ${acer4kFlags}"
        lg_val="${lgMonitor}, ${lgMode}, 2560x0, 1, transform, 1"
        profile="4k"
        ;;
    esac

    mkdir -p "$(dirname ${monitorConfFile})"
    printf 'monitor = %s\nmonitor = %s\n' "$acer_val" "$lg_val" > ${monitorConfFile}

    ${hyprPackage}/bin/hyprctl --batch "keyword monitor $acer_val ; keyword monitor $lg_val" >/dev/null

    mkdir -p "$(dirname ${monitorStateFile})"
    printf '%s\n' "$profile" > ${monitorStateFile}
    sleep 0.3
  '';

  # ─── Manual toggle (Super+Shift+M) ──────────────────────────────────────
  hyprMonitorToggle = pkgs.writeShellScriptBin "hypr-monitor-toggle" ''
    #!/usr/bin/env bash
    set -eu

    current_width="$(${hyprPackage}/bin/hyprctl -j monitors \
      | ${pkgs.jq}/bin/jq -r \
        --arg desc "${acerDesc}" \
        '.[] | select(.description == $desc) | .width')"

    if [[ "$current_width" == "3840" ]]; then
      target="perf"
      msg="Acer → 1080p @ 320Hz — toggle DFR On in OSD now"
    else
      target="4k"
      msg="Acer → 4K @ 160Hz — toggle DFR Off in OSD now"
    fi

    ${applyProfile} "$target"
    ${pkgs.libnotify}/bin/notify-send -t 4000 "Display" "$msg" || true
  '';

  # ─── Boot-time profile restore ──────────────────────────────────────────
  hyprApplyMonitorProfile = pkgs.writeShellScriptBin "hypr-apply-monitor-profile" ''
    #!/usr/bin/env bash
    set -eu

    profile="4k"
    if [[ -f ${monitorStateFile} ]]; then
      profile="$(cat ${monitorStateFile})"
    fi

    ${applyProfile} "$profile"
  '';

  # ─── Auto-detect profile from monitor's advertised mode ─────────────────
  # Called whenever monitoradded fires (DFR toggle, hotplug, etc.). Hyprland's
  # socket event contains the connector name (e.g. DP-1), not the EDID desc, so
  # the script queries monitors itself and exits unless the Acer is present.
  hyprAutoDetectProfile = pkgs.writeShellScriptBin "hypr-auto-detect-profile" ''
    #!/usr/bin/env bash
    set -eu

    preferred=""
    modes=""

    # After a DFR toggle the monitor is re-added before EDID/mode info has fully
    # settled. Retry briefly so the first DFR-on transition can be corrected
    # automatically instead of leaving Hyprland's default 4K profile active.
    for _ in {1..20}; do
      monitor_json="$(${hyprPackage}/bin/hyprctl -j monitors all)"
      preferred="$(printf '%s\n' "$monitor_json" \
        | ${pkgs.jq}/bin/jq -r \
          --arg desc "${acerDesc}" \
          '.[] | select(.description == $desc) | .availableModes[0] // empty')"
      modes="$(printf '%s\n' "$monitor_json" \
        | ${pkgs.jq}/bin/jq -r \
          --arg desc "${acerDesc}" \
          '.[] | select(.description == $desc) | (.availableModes // [])[]')"

      if [[ -n "$preferred" ]]; then
        break
      fi
      sleep 0.25
    done

    # Monitor not present or query failed
    if [[ -z "$preferred" ]]; then
      exit 0
    fi

    # Decide target profile based on advertised native mode
    case "$preferred" in
      1920x1080@320*|1920x1080@319*)
        target="perf"
        msg="DFR On detected → applying 1080p @ 320Hz"
        ;;
      3840x2160*)
        target="4k"
        msg="DFR Off detected → applying 4K @ 160Hz"
        ;;
      *)
        # Fallback for DFR-on EDIDs where the preferred mode is not first but
        # the 320Hz performance mode is advertised.
        if printf '%s\n' "$modes" | ${pkgs.gnugrep}/bin/grep -Eq '^1920x1080@(319|320)'; then
          target="perf"
          msg="DFR On detected → applying 1080p @ 320Hz"
        else
          # Unknown preferred mode — leave alone
          exit 0
        fi
        ;;
    esac

    # Check what we're currently sending; skip if already correct
    current_width="$(${hyprPackage}/bin/hyprctl -j monitors \
      | ${pkgs.jq}/bin/jq -r \
        --arg desc "${acerDesc}" \
        '.[] | select(.description == $desc) | .width // empty')"

    if [[ "$target" == "perf" && "$current_width" == "1920" ]]; then
      exit 0  # already in perf mode
    fi
    if [[ "$target" == "4k" && "$current_width" == "3840" ]]; then
      exit 0  # already in 4k mode
    fi

    ${applyProfile} "$target"
    ${pkgs.libnotify}/bin/notify-send -t 3000 "Display" "$msg" || true
  '';

  # ─── Restart status bar and reapply monitor profile ────────────────────
  hyprRestartDms = pkgs.writeShellScriptBin "hypr-restart-dms" ''
    #!/usr/bin/env bash
    set -eu

    pkill dms || true
    dms run
  '';

  # ─── Event listener: watches Hyprland's socket for monitor changes ─────
  hyprMonitorWatcher = pkgs.writeShellScript "hypr-monitor-watcher" ''
    #!/usr/bin/env bash
    set -eu

    while [[ -z "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; do
      if [[ -d "$XDG_RUNTIME_DIR/hypr" ]]; then
        sig="$(ls -t "$XDG_RUNTIME_DIR/hypr" | head -n1)"
        if [[ -n "$sig" ]]; then
          export HYPRLAND_INSTANCE_SIGNATURE="$sig"
          break
        fi
      fi
      sleep 1
    done

    socket="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
    while [[ ! -S "$socket" ]]; do
      sleep 0.5
    done

    ${pkgs.socat}/bin/socat -U - UNIX-CONNECT:"$socket" | while IFS= read -r line; do
      # monitoradded events carry connector names, not EDID descriptions. Run the
      # detector for every added monitor; it verifies the Acer description itself.
      if [[ "$line" == monitoradded* ]]; then
        ${hyprAutoDetectProfile}/bin/hypr-auto-detect-profile &
      fi
    done
  '';

in
{
  home.packages = [
    hyprMonitorToggle
    hyprApplyMonitorProfile
    hyprRestartDms
    hyprAutoDetectProfile
    pkgs.jq
    pkgs.socat
    pkgs.libnotify
  ];

  # Seed monitors.conf with the 4k default if it doesn't exist yet, so hyprland
  # has something to source on first boot before any profile has been applied.
  home.activation.seedHyprMonitorsConf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    conf="$HOME/.config/hypr/monitors.conf"
    if [[ ! -f "$conf" ]]; then
      mkdir -p "$(dirname "$conf")"
      {
        printf 'monitor = %s, %s, 0x0, 1.5, %s\n' "${acerMonitor}" "${acer4kMode}" "${acer4kFlags}"
        printf 'monitor = %s, %s, 2560x0, 1, transform, 1\n' "${lgMonitor}" "${lgMode}"
      } > "$conf"
    fi
  '';

  # ─── Systemd user service to run the watcher ───────────────────────────
  systemd.user.services.hypr-monitor-watcher = {
    Unit = {
      Description = "Watch Hyprland for Acer XV272K DFR changes";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${hyprMonitorWatcher}";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  wayland.windowManager.hyprland.settings = {
    workspace = [
      "1, monitor:${acerMonitor}"
      "2, monitor:${acerMonitor}"
      "3, monitor:${acerMonitor}"
      "4, monitor:${acerMonitor}"
      "5, monitor:${acerMonitor}"
      "6, monitor:${lgMonitor}"
      "7, monitor:${lgMonitor}"
      "8, monitor:${lgMonitor}"
      "9, monitor:${lgMonitor}"
      "10, monitor:${lgMonitor}"
    ];

    cursor = {
      no_hardware_cursors = true;
    };

    render = {
      cm_auto_hdr = 2;
      direct_scanout = 1;
      send_content_type = true;
    };

    exec-once = [
      "hypr-apply-monitor-profile"
    ];
  };

  wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
    source = ~/.config/hypr/monitors.conf
    unbind = $mainMod, x
    unbind = $mainMod SHIFT, M
    bind = $mainMod, x, exec, hypr-restart-dms
    bind = $mainMod SHIFT, M, exec, hypr-monitor-toggle
  '';
}
