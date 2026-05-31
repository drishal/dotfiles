{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [ inputs.dms.homeModules.dank-material-shell ];

  home.packages = with pkgs; [
    curl
    python3
  ];

  home.file.".config/DankMaterialShell/plugins/DankHermes".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/config/DankHermes";

  # Merge instead of owning the file: DMS stores all plugin runtime settings here.
  home.activation.enableDankHermesPlugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.python3}/bin/python3 - <<'PY'
    import json
    import os
    from pathlib import Path

    path = Path(os.path.expanduser("~/.config/DankMaterialShell/plugin_settings.json"))
    path.parent.mkdir(parents=True, exist_ok=True)
    try:
        data = json.loads(path.read_text()) if path.exists() else {}
    except Exception:
        data = {}
    plugin = data.setdefault("dankHermes", {})
    plugin["enabled"] = True
    plugin.setdefault("apiBaseUrl", "http://127.0.0.1:8642")
    plugin.setdefault("hermesHome", "~/.hermes")
    path.write_text(json.dumps(data, indent=2) + "\n")
    PY
  '';

  programs.dank-material-shell = {
    enable = true;

    # settings = builtins.fromJSON (builtins.readFile ./dms.json);
    settings = {
      showWorkspaceIndex = true;
      showSeconds = true;
      clockDateFormat = "d MMM yyyy (ddd)";
      blurEnabled = true;
      soundNewNotification = false;

      # Disable bar hiding on fullscreen — DMS checks per-screen not per-workspace
      # on Sway, so it hides on ALL workspaces when ANY window is fullscreen
      barConfigs = [
        {
          id = "default";
          name = "Main Bar";
          enabled = true;
          position = 0;
          fullscreenDetection = false;

          screenPreferences = [ "all" ];
          showOnLastDisplay = true;

          leftWidgets = [
            "launcherButton"
            "workspaceSwitcher"
            "focusedWindow"
          ];

          centerWidgets = [
            # "music"
            "clock"
            "notificationButton"
          ];

          rightWidgets = [
            "clipboard"
            "cpuUsage"
            { widgetId = "memUsage"; showInGb = true; }
            "battery"
            "controlCenterButton"
            "powerMenuButton"
            "dankHermes"
            "systemTray"
          ];
        }
      ];
    };

    # Session-level settings (stored in ~/.local/state/DankMaterialShell/session.json)
    # Weather defaults to New York — override to Ahmedabad
    session = {
      weatherLocation = "Ahmedabad, India";
      weatherCoordinates = "23.0225,72.5714";
    };
  };
}
