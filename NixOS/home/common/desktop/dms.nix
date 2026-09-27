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
    # The one python3 on PATH (a second python in home.packages would collide on
    # bin/python3). Beyond DMS, it carries the PDF libraries for pi's `pdf` skill
    # (~/.pi/agent/skills/pdf) and pi's `eval` tool.
    (python3.withPackages (ps: with ps; [
      pypdf
      pdfplumber
      reportlab
      pdf2image
      pytesseract
      pypdfium2
      pillow
    ]))
    tesseract # OCR for the pdf skill (pytesseract calls the binary)
  ];


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
