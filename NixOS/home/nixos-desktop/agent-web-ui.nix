{ config, lib, pkgs, ... }:

# agent-web-ui: web UI for pi and omp on 127.0.0.1:4783. The app stays a git checkout
# (~/Desktop/git-stuff/webui); after pulling, `npm run build` there, then restart this unit.
let
  appDir = "%h/Desktop/git-stuff/webui";
in
{
  systemd.user.services.agent-web-ui = {
    Unit = {
      Description = "Agent Web UI for pi and omp (127.0.0.1:4783)";
      ConditionPathExists = "${appDir}/dist/server/server/index.js";
    };
    Install.WantedBy = [ "default.target" ];
    Service = {
      ExecStart = "${lib.getExe pkgs.nodejs} ${appDir}/dist/server/server/index.js";
      WorkingDirectory = appDir;
      Environment = [
        "PORT=4783"
        "WORKSPACE_ROOTS=%h"
        # The shell's toolset: omp is in ~/.local/bin, and the agents' tools need the rest.
        "PATH=%h/.local/bin:%h/.node_modules/bin:%h/.cargo/bin:%h/.bun/bin:/run/wrappers/bin:${config.home.profileDirectory}/bin:/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin"
      ];
      # "always": SIGTERM exits 0, so "on-failure" would leave it dead after a kill by name.
      Restart = "always";
      RestartSec = 5;
    };
  };
}
