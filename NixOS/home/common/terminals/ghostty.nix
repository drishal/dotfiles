{ config, lib, pkgs, ... }:
let
  enabled = config.drishal.defaultApps.terminal == "ghostty";
  service = "app-com.mitchellh.ghostty.service";
  link = ".config/systemd/user/graphical-session.target.wants/${service}";
  systemctl = "XDG_RUNTIME_DIR=\${XDG_RUNTIME_DIR:-/run/user/$(id -u)} ${config.systemd.user.systemctlPath}";
in
lib.mkMerge [
  (lib.mkIf enabled {
    home.file.${link}.source = "${config.programs.ghostty.package}/share/systemd/user/${service}";
    xdg.configFile."systemd/user/app-com.mitchellh.ghostty.service.d/10-profile-exec.conf".text = ''
      [Service]
      ExecStart=
      ExecStart=${config.home.profileDirectory}/bin/ghostty --gtk-single-instance=true --initial-window=false
    '';
    programs.ghostty.settings = {
      quit-after-last-window-closed = false;
      # Avoid a synchronous systemd scope request for every new terminal.
      linux-cgroup = "never";
    };
  })
  {
    # No display? Leave activation to D-Bus or the next graphical login.
    # Never stop or restart a running terminal owner on a switch.
    home.activation.ghosttyLauncher = lib.hm.dag.entryAfter [ "reloadSystemd" ] ''
      ${lib.optionalString (!enabled) ''rm -f "$HOME/${link}"''}
      ${lib.optionalString enabled ''
        if [[ $(${systemctl} --user is-system-running 2>/dev/null || true) =~ ^(running|degraded)$ ]] &&
            ${systemctl} --user show-environment | ${pkgs.gnugrep}/bin/grep -Eq '^DISPLAY=|^WAYLAND_DISPLAY='; then
          ${systemctl} --user start ${service}
        fi
      ''}
    '';
  }
]
