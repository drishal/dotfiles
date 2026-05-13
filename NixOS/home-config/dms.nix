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
