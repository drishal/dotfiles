{
  config,
  lib,
  pkgs,
  ...
}:

# Standalone Hermes desktop app.
#
# A self-contained Quickshell program (no Dank Material Shell dependency) living
# at config/HermesApp/. This module exposes it as a launchable `hermes-app`
# command plus a desktop entry.
#
# The shell.qml is referenced from the live repo checkout (~/dotfiles), so QML
# tweaks take effect on next launch without a home-manager rebuild — same
# editing workflow as the DankHermes DMS plugin. The HermesService backend
# shells out to curl and python3, so both are pinned into the wrapper's PATH.
let
  appRoot = "${config.home.homeDirectory}/dotfiles/config/HermesApp";

  hermes-app = pkgs.writeShellScriptBin "hermes-app" ''
    export PATH=${
      lib.makeBinPath [
        pkgs.curl
        pkgs.python3
        pkgs.procps
      ]
    }:$PATH

    # Single instance: if a window is already open, do nothing. Closing the
    # window quits the process (shell.qml onClosed), so this only blocks while
    # the app is genuinely up.
    if pgrep -f "qs -p ${appRoot}/shell.qml" >/dev/null 2>&1; then
      exit 0
    fi

    exec ${pkgs.quickshell}/bin/qs -p ${appRoot}/shell.qml "$@"
  '';
in
{
  home.packages = [
    hermes-app
    pkgs.curl
    pkgs.python3
  ];

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
