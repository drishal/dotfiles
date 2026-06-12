{
  config,
  lib,
  pkgs,
  ...
}:

# Standalone Hermes desktop app.
#
# A PySide6 (Qt Quick) program. The UI is QML; the backend is in-process Python
# (httpx for HTTP/SSE, sqlite3 for the DB), so there's no Quickshell, no
# curl/python3 subprocesses, and no DMS dependency. This module exposes it as a
# launchable `hermes-app` command + desktop entry.
#
# The app lives in its own repo (github.com/drishal/hermes-app), checked out at
# ~/Desktop/git-stuff/hermes-app. main.py is referenced from that live working
# tree, so QML/Python tweaks take effect on next launch without a home-manager
# rebuild. Clone it there, or adjust appRoot below.
#
# The welcome dashboard shells out to the `hermes` CLI, which is expected on the
# user's PATH (inherited); everything else is self-contained in the python env.
let
  appRoot = "${config.home.homeDirectory}/Desktop/git-stuff/hermes-app";

  pyEnv = pkgs.python3.withPackages (
    ps: with ps; [
      pyside6
      httpx
      pygments
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

  # Derive the app palette from the active stylix scheme. Theme.qml reads this
  # at startup (base24 slots → its token surface), falling back to its bundled
  # gruvbox defaults when the file is absent. Refreshes on home-manager switch.
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
