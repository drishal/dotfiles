{
  config,
  inputs,
  pkgs,
  ...
}:

{
  imports = [ inputs.dms.homeModules.dank-material-shell ];

  programs.dank-material-shell = {
    enable = true;

    # settings = builtins.fromJSON (builtins.readFile ./dms.json);
    settings = {
      showWorkspaceIndex = true;

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
            "systemTray"
          ];
        }
      ];
    };
  };
}
