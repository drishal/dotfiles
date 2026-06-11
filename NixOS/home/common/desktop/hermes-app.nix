{
  config,
  lib,
  pkgs,
  ...
}:

# Standalone Hermes desktop app.
#
# A PySide6 (Qt Quick) program living at config/HermesApp/. The UI is QML; the
# backend is in-process Python (httpx for HTTP/SSE, sqlite3 for the DB), so
# there's no Quickshell, no curl/python3 subprocesses, and no DMS dependency.
# This module exposes it as a launchable `hermes-app` command + desktop entry.
#
# main.py is referenced from the live repo checkout (~/dotfiles), so QML/Python
# tweaks take effect on next launch without a home-manager rebuild.
#
# The welcome dashboard shells out to the `hermes` CLI, which is expected on the
# user's PATH (inherited); everything else is self-contained in the python env.
let
  appRoot = "${config.home.homeDirectory}/dotfiles/config/HermesApp";

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
