# Nix packages Hermes and runs its gateway; ~/.hermes (config.yaml, .env, plugins) stays imperative.
# The upstream services.hermes-agent is not used: it writes ~/.hermes/.managed and sets HERMES_MANAGED,
# and either one makes `hermes model` / `hermes config set` refuse.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  hermes = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  home.packages = [ hermes ];

  # Not named hermes-gateway: `hermes gateway start/restart` rewrites that unit file, and on a Nix
  # install `hermes gateway install` writes an ExecStart that does not exist. Restart with systemctl.
  systemd.user.services.hermes-agent = {
    Unit.Description = "Hermes Agent Gateway";
    Install.WantedBy = [ "default.target" ];
    Service = {
      ExecStart = "${lib.getExe hermes} gateway";
      WorkingDirectory = config.home.homeDirectory;
      Environment = [
        "HERMES_HOME=${config.home.homeDirectory}/.hermes"
        "HERMES_SUPERVISED_CHILD=1"
        # The shell's toolset, so the agent's terminal tool and systemd-run work from the gateway.
        "PATH=${config.home.profileDirectory}/bin:/run/wrappers/bin:/run/current-system/sw/bin"
      ];
      # Exit codes mirror the unit Hermes generates: 75 = restart requested, 78 = fatal config.
      Restart = "always";
      RestartSec = 5;
      RestartForceExitStatus = 75;
      SuccessExitStatus = 75;
      RestartPreventExitStatus = 78;
      KillMode = "mixed";
      UMask = "0077";
    };
  };
}
