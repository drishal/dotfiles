# Nix packages Hermes from numtide's llm-agents.nix and runs its gateway;
# ~/.hermes (config.yaml, .env, plugins) stays imperative.
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
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
  hermes = llmAgents.hermes-agent;
in
{
  # numtide ships the desktop app separately (`hermes desktop` cannot build from a Nix install).
  # Plugins install natively into ~/.hermes/plugins (`hermes plugins install`, or the plugin's own
  # installer); numtide's package has no extraPythonPackages hook to inject them from Nix.
  home.packages = [
    hermes
    llmAgents.hermes-desktop
  ];

  # numtide's cache carries hermes-agent, hermes-desktop and their python deps, so this builds
  # nothing locally. Written as a file rather than nix.settings, which asserts on nix.package.
  home.file.".config/nix/nix.conf".text = ''
    extra-substituters = https://cache.numtide.com
    extra-trusted-public-keys = niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=
  '';

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
        # No HERMES_INSTALL_ROOT: numtide bakes the install stamp inside site-packages, which is
        # where pm.paths.install_stamp_path looks when the variable is unset.
        # The shell's toolset, so the agent's terminal tool and systemd-run work from the gateway.
        "PATH=${config.home.profileDirectory}/bin:/run/wrappers/bin:/run/current-system/sw/bin:${config.home.homeDirectory}/.local/bin"
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

  # hermes-webui is deliberately absent: the ~/hermes-webui clone is gone, and its unit pinned
  # upstream-only internals (hermesVenv, the derived hermes-python wrapper) numtide does not expose.
}
