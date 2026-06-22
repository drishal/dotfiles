{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.generators) mkLuaInline;

  hyprPackage = config.wayland.windowManager.hyprland.package;

  # ─── Monitor identifiers ────────────────────────────────────────────────
  acerMonitor = "desc:Acer Technologies XV272K V5 15391B0344201";
  lgMonitor = "desc:LG Electronics LG ULTRAGEAR 302NTUW8G822";
  acerDesc = "Acer Technologies XV272K V5 15391B0344201";

  # ─── Modes ──────────────────────────────────────────────────────────────
  acer4kMode = "3840x2160@160";
  acerPerfMode = "1920x1080@320";
  lgMode = "1920x1080@143.98";

  # HDR override params (lua, for `hyprctl eval hl.monitor`). EDID HDR metadata;
  # sdrbrightness lifts SDR/desktop content so it isn't dim (DisplayHDR 400).
  acerHdrExtra = ''bitdepth = 10, cm = "hdredid", sdrbrightness = 1.2, sdrsaturation = 1.0'';

  # ─── Generated monitor config ───────────────────────────────────────────
  # Under the Lua config the persisted layout is a Lua fragment dofile()'d by
  # hyprland.lua (see extraConfig below) so reloads don't clobber it.
  monitorLuaFile = "$HOME/.config/hypr/monitors.lua";

  # ─── Profile applier ───────────────────────────────────────────────────
  # Writes the active monitor layout to a dofile()'d Lua fragment so hyprctl
  # reloads (home-manager switch, manual reloads, etc.) don't clobber it, then
  # applies it immediately via `hyprctl eval` for the live session.
  applyProfile = pkgs.writeShellScript "hypr-apply-profile-impl" ''
    #!/usr/bin/env bash
    set -eu

    profile="''${1:-4k}"

    # This always re-applies cm,srgb, so any active HDR override is now stale.
    rm -f "$HOME/.config/hypr/hdr-on" 2>/dev/null || true

    case "$profile" in
      perf)
        acer_lua='hl.monitor({ output = "${acerMonitor}", mode = "${acerPerfMode}", position = "0x0", scale = 1, bitdepth = 8, cm = "srgb" })'
        lg_lua='hl.monitor({ output = "${lgMonitor}", mode = "${lgMode}", position = "1920x0", scale = 1, transform = 1 })'
        ;;
      4k|*)
        acer_lua='hl.monitor({ output = "${acerMonitor}", mode = "${acer4kMode}", position = "0x0", scale = 1.5, bitdepth = 10, cm = "srgb" })'
        lg_lua='hl.monitor({ output = "${lgMonitor}", mode = "${lgMode}", position = "2560x0", scale = 1, transform = 1 })'
        profile="4k"
        ;;
    esac

    mkdir -p "$(dirname ${monitorLuaFile})"
    printf '%s\n%s\n' "$acer_lua" "$lg_lua" > ${monitorLuaFile}

    # Lua-parser Hyprland rejects `hyprctl keyword`; apply live via `eval`.
    ${hyprPackage}/bin/hyprctl eval "$acer_lua" >/dev/null
    ${hyprPackage}/bin/hyprctl eval "$lg_lua" >/dev/null
    sleep 0.3
  '';

  # ─── Manual toggle (Super+Shift+M) ──────────────────────────────────────
  hyprMonitorToggle = pkgs.writeShellScriptBin "hypr-monitor-toggle" ''
    #!/usr/bin/env bash
    set -eu

    height="$(${hyprPackage}/bin/hyprctl -j monitors \
      | ${pkgs.jq}/bin/jq -r \
        --arg desc "${acerDesc}" \
        '.[] | select(.description == $desc) | .height')"

    # Above 1080p means we're in a 4K profile → drop to perf; otherwise go up.
    if [[ "$height" =~ ^[0-9]+$ ]] && (( height > 1080 )); then
      target="perf"
      msg="Acer → 1080p @ 320Hz — toggle DFR On in OSD now"
    else
      target="4k"
      msg="Acer → 4K @ 160Hz — toggle DFR Off in OSD now"
    fi

    ${applyProfile} "$target"
    ${pkgs.libnotify}/bin/notify-send -t 4000 "Display" "$msg" || true
  '';

  # ─── HDR toggle (Super+Shift+H) ─────────────────────────────────────────
  # Transient: flips the Acer to HDR (cm,hdredid + 10-bit + SDR boost) live on
  # whichever mode is active. A DFR/resolution change or reload reverts to SDR
  # (applyProfile clears the state file and re-applies cm,srgb) — re-press to
  # re-enable. HDR is opt-in this way so it's only on when actually wanted.
  hyprHdrToggle = pkgs.writeShellScriptBin "hypr-hdr-toggle" ''
    #!/usr/bin/env bash
    set -eu

    state="$HOME/.config/hypr/hdr-on"

    width="$(${hyprPackage}/bin/hyprctl -j monitors \
      | ${pkgs.jq}/bin/jq -r \
        --arg desc "${acerDesc}" \
        '.[] | select(.description == $desc) | .width')"

    if [[ -z "$width" || "$width" == "null" ]]; then
      ${pkgs.libnotify}/bin/notify-send -t 3000 "HDR" "Acer not found" || true
      exit 0
    fi

    if [[ -e "$state" ]]; then
      # Currently HDR → back to SDR via the normal profile applier (which also
      # removes the state file).
      if [[ "$width" == "3840" ]]; then ${applyProfile} 4k; else ${applyProfile} perf; fi
      ${pkgs.libnotify}/bin/notify-send -t 3000 "Display" "HDR off — SDR (cm,srgb)" || true
    else
      # Currently SDR → enable HDR on the active mode.
      if [[ "$width" == "3840" ]]; then
        line='hl.monitor({ output = "${acerMonitor}", mode = "${acer4kMode}", position = "0x0", scale = 1.5, ${acerHdrExtra} })'
      else
        line='hl.monitor({ output = "${acerMonitor}", mode = "${acerPerfMode}", position = "0x0", scale = 1, ${acerHdrExtra} })'
      fi
      ${hyprPackage}/bin/hyprctl eval "$line" >/dev/null
      touch "$state"
      ${pkgs.libnotify}/bin/notify-send -t 3000 "Display" "HDR on — cm,hdredid (SDR boost 1.2)" || true
    fi
  '';

  # ─── Boot-time profile detection ────────────────────────────────────────
  hyprApplyMonitorProfile = pkgs.writeShellScriptBin "hypr-apply-monitor-profile" ''
    #!/usr/bin/env bash
    set -eu

    ${hyprAutoDetectProfile}/bin/hypr-auto-detect-profile
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

    # In DFR mode the EDID advertises 1920x1080@320 *and still lists* the 4K
    # modes, so the 320Hz mode's presence is the unambiguous DFR-On signal and
    # must be checked first — otherwise a 4K match wins and strands the panel.
    if printf '%s\n' "$modes" | ${pkgs.gnugrep}/bin/grep -Eq '^1920x1080@(319|320)'; then
      target="perf"
      msg="DFR On detected → applying 1080p @ 320Hz"
    elif printf '%s\n' "$modes" | ${pkgs.gnugrep}/bin/grep -Eq '^3840x2160@'; then
      target="4k"
      msg="DFR Off detected → applying 4K @ 160Hz"
    else
      case "$preferred" in
        3840x2160*)
          target="4k"
          msg="DFR Off detected → applying 4K @ 160Hz"
          ;;
        1920x1080@320*|1920x1080@319*)
          target="perf"
          msg="DFR On detected → applying 1080p @ 320Hz"
          ;;
        *)
          # Unknown mode list — leave Hyprland's highres bootstrap alone.
          exit 0
          ;;
      esac
    fi

    ${applyProfile} "$target"
    ${pkgs.libnotify}/bin/notify-send -t 3000 "Display" "$msg" || true
  '';

  # ─── Restart widget stack ──────────────────────────────────────────────
  hyprRestartWidgets = pkgs.writeShellScriptBin "hypr-restart-widgets" ''
    #!/usr/bin/env bash
    set -eu
    ${widgetRestart.${config.drishal.widgets}}
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

    restart_pid=""
    ${pkgs.socat}/bin/socat -U - UNIX-CONNECT:"$socket" | while IFS= read -r line; do
      # monitoradded events carry connector names, not EDID descriptions. Run the
      # detector for every added monitor; it verifies the Acer description itself.
      if [[ "$line" == monitoradded* ]]; then
        ${hyprAutoDetectProfile}/bin/hypr-auto-detect-profile &
        # The re-add tears down the bar's layer-surfaces, so the active widget
        # stack crashes. Restart it 3s later (debounced across rapid events),
        # parented to Hyprland via hl.exec_cmd so it gets the compositor env and
        # survives a watcher restart.
        [[ -n "$restart_pid" ]] && kill "$restart_pid" 2>/dev/null || true
        ( sleep 3; ${hyprPackage}/bin/hyprctl eval 'hl.exec_cmd("${hyprRestartWidgets}/bin/hypr-restart-widgets")' >/dev/null ) &
        restart_pid=$!
      fi
    done
  '';

  # ─── Widget-stack restart helpers ─────────────────────────────────────
  ewwLaunch = config.xdg.configHome + "/eww/scripts/launch.sh";
  widgetRestart = {
    "dms"    = "pkill dms; dms run";
    "eww"    = "pkill end-rs || true; end-rs daemon & ${ewwLaunch}";
    "waybar" = "pkill waybar; waybar &";
    # ags quit can fail silently on a wedged instance that keeps the dbus name; force-kill leftover gjs so the relaunch isn't a no-op remote.
    "ags"    = "ags quit 2>/dev/null; pkill -9 -f 'gjs.*ags.js'; ags run &";
  };

in
{
  home.packages = [
    hyprMonitorToggle
    hyprHdrToggle
    hyprApplyMonitorProfile
    hyprRestartWidgets
    hyprAutoDetectProfile
    pkgs.jq
    pkgs.socat
    pkgs.libnotify
  ];

  # Keep the dofile()'d startup fragment EDID-safe. Exact profiles are applied
  # after Hyprland can query the monitor's currently advertised modes.
  home.activation.seedHyprMonitorsConf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    conf="$HOME/.config/hypr/monitors.lua"
    mkdir -p "$(dirname "$conf")"
    {
      printf 'hl.monitor({ output = "%s", mode = "highres", position = "0x0", scale = "auto", bitdepth = 8, cm = "srgb" })\n' "${acerMonitor}"
      printf 'hl.monitor({ output = "%s", mode = "preferred", position = "auto-right", scale = 1, transform = 1 })\n' "${lgMonitor}"
    } > "$conf"
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
    config = {
      cursor = {
        no_hardware_cursors = true;
      };
      render = {
        # HDR is fully manual via Super+Shift+H — no per-app auto-switching
        cm_auto_hdr = 0;
        direct_scanout = 1;
        send_content_type = true;
      };
    };

    workspace_rule =
      map (i: {
        workspace = toString i;
        monitor = acerMonitor;
      }) (lib.range 1 5)
      ++ map (i: {
        workspace = toString i;
        monitor = lgMonitor;
      }) (lib.range 6 10);

    on = [
      {
        _args = [
          "hyprland.start"
          (mkLuaInline ''
            function()
              hl.exec_cmd("hypr-apply-monitor-profile")
            end'')
        ];
      }
    ];
  };

  # Appended raw to hyprland.lua: load the persisted monitor layout on every
  # (re)load, and override SUPER+SHIFT+M from the common "layout master" bind to
  # the DFR display toggle.
  wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
    do
      local hm_mon = os.getenv("HOME") .. "/.config/hypr/monitors.lua"
      local f = io.open(hm_mon)
      if f then
        f:close()
        dofile(hm_mon)
      end
    end

    hl.unbind("SUPER + SHIFT + M")
    hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("hypr-monitor-toggle"))

    hl.bind("SUPER + SHIFT + H", hl.dsp.exec_cmd("hypr-hdr-toggle"))
  '';
}
