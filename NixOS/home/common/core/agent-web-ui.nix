{ config, lib, pkgs, ... }:

# agent-web-ui: web UI for pi, omp, and hermes. The app stays a git checkout (~/Desktop/git-stuff/webui).
# Settings live in ~/.config/agentwebui/config.yml. After pulling: `npm run build`, then restart this unit.
let
  appDir = "%h/Desktop/git-stuff/webui";
in
{
  systemd.user.services.agent-web-ui = {
    Unit = {
      Description = "Agent Web UI for pi, omp, and hermes";
      ConditionPathExists = "${appDir}/dist/server/server/index.js";
    };
    Install.WantedBy = [ "default.target" ];
    Service = {
      ExecStart = "${lib.getExe pkgs.nodejs} ${appDir}/dist/server/server/index.js";
      WorkingDirectory = appDir;
      # Only PATH: anything else set here would override config.yml.
      Environment = [
        # The shell's toolset: omp is in ~/.local/bin, and the agents' tools need the rest.
        "PATH=%h/.local/bin:%h/.node_modules/bin:%h/.cargo/bin:%h/.bun/bin:/run/wrappers/bin:${config.home.profileDirectory}/bin:/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin"
      ];
      # "always": SIGTERM exits 0, so "on-failure" would leave it dead after a kill by name.
      Restart = "always";
      RestartSec = 5;
      # 78 = bad settings in config.yml (e.g. host 0.0.0.0 without a login); the journal says why.
      RestartPreventExitStatus = 78;
    };
  };
}
