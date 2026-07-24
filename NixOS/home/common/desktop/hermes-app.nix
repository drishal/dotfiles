{
  config,
  lib,
  pkgs,
  ...
}:

# Standalone Hermes desktop app — PySide6/QML UI with an in-process Python backend,
# exposed here as a `hermes-app` command + desktop entry.
#
# Lives in its own repo (github.com/drishal/hermes-app) at ~/Desktop/git-stuff/hermes-app;
# main.py is read from that working tree, so edits apply on next launch without a rebuild.
#
# The welcome dashboard shells out to the `hermes` CLI, expected on the inherited PATH.
let
  appRoot = "${config.home.homeDirectory}/Desktop/git-stuff/hermes-app";

  pyEnv = pkgs.python3.withPackages (
    ps: with ps; [
      pyside6
      httpx
      pygments
      pyyaml
    ]
  );

  hermes-app = pkgs.writeShellScriptBin "hermes-app" ''
    export PATH=${lib.makeBinPath [ pkgs.procps ]}:$PATH

    # Single instance: if a window is already open, do nothing. Closing the
    # window quits the process, so this only blocks while the app is genuinely up.
    if pgrep -f "${appRoot}/main.py" >/dev/null 2>&1; then
      exit 0
    fi

    exec ${pyEnv}/bin/python3 ${appRoot}/main.py "$@"
  '';
in
{
  home.packages = [ hermes-app ];

  # Theme.qml reads this at startup, falling back to bundled gruvbox if absent
  xdg.configFile."HermesApp/colors.json".text =
    let
      c = config.lib.stylix.colors;
    in
    builtins.toJSON {
      base00 = "#${c.base00}";
      base01 = "#${c.base01}";
      base02 = "#${c.base02}";
      base03 = "#${c.base03}";
      base04 = "#${c.base04}";
      base05 = "#${c.base05}";
      base08 = "#${c.base08}";
      base0A = "#${c.base0A}";
      base0B = "#${c.base0B}";
      base0C = "#${c.base0C}";
      base0D = "#${c.base0D}";
      base0E = "#${c.base0E}";
    };

  xdg.desktopEntries.hermes-app = {
    name = "Hermes Agent";
    comment = "Hermes coding agent chat";
    exec = "hermes-app";
    icon = "utilities-terminal";
    terminal = false;
    categories = [
      "Development"
      "Utility"
    ];
  };
}
