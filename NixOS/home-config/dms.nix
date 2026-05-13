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
      useAutoLocation = false;
      weatherLocation = "Ahmedabad, Gujarat";
      weatherCoordinates = "22.7455391,72.2974907";
      barConfigs = [
        {
          id = "default";
          name = "Main Bar";
          enabled = true;
          position = 0;

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
            "weather"
          ];

          rightWidgets = [
            "clipboard"
            "cpuUsage"
            "memUsage"
            "battery"
            "controlCenterButton"
            "systemTray"
          ];
        }
      ];
    };
  };
}
