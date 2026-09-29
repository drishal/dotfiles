# Nix packages Hermes and runs its gateway and webui; ~/.hermes (config.yaml, .env, plugins) stays imperative.
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
  hermesBase = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # Plugins that need Python packages go here: the venv is read-only, so runtime installs can't add them.
  hermes = hermesBase.override {
    extraPythonPackages = [ (hermesBase.python.pkgs.callPackage ./hermes/mnemosyne.nix { }) ];
  };

  # The CLI wrapper's environment (plugin PYTHONPATH, bundled resources) ending in the interpreter,
  # for hermes-webui, which runs the agent in-process.
  hermesPython = pkgs.runCommand "hermes-python" { } ''
    wrapper=${lib.getExe hermes}
    tail -n1 "$wrapper" | grep -q '^exec ' || { echo "hermes wrapper no longer ends in exec" >&2; exit 1; }
    mkdir -p $out/bin
    { sed '$d' "$wrapper"; echo 'exec ${hermes.hermesVenv}/bin/python3 "$@"'; } > $out/bin/hermes-python
    chmod +x $out/bin/hermes-python
  '';
in
{
  # `hermes desktop` builds from a source checkout and cannot work here; hermesDesktop is the
  # prebuilt app (`hermes-desktop` + launcher), pinned to this `hermes`.
  home.packages = [
    hermes
    hermes.hermesDesktop
  ];

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

  # The webui stays a git clone at ~/hermes-webui; this pins what it runs. Left to discover an agent,
  # it picks up a ~/.hermes/hermes-agent checkout (or curl|bash installs one) whose pm fights this one.
  systemd.user.services.hermes-webui = {
    Unit = {
      Description = "Hermes WebUI";
      After = [
        "network-online.target"
        "hermes-agent.service"
      ];
      Wants = [ "network-online.target" ];
      Requires = [ "hermes-agent.service" ];
      ConditionPathExists = "%h/hermes-webui/bootstrap.py";
      StartLimitIntervalSec = 0;
    };
    Install.WantedBy = [ "default.target" ];
    Service = {
      ExecStartPre = "-%h/.local/bin/hermes-webui-update.sh";
      ExecStart = "%h/hermes-webui/.venv/bin/python %h/hermes-webui/bootstrap.py --no-browser --skip-agent-install";
      WorkingDirectory = "%h/hermes-webui";
      Environment = [
        "HERMES_HOME=%h/.hermes"
        "HERMES_WEBUI_PYTHON=${hermesPython}/bin/hermes-python"
        "HERMES_WEBUI_AGENT_DIR=${hermes.hermesVenv}/${hermesBase.python.sitePackages}"
        # The server otherwise runs from the agent dir, which is read-only.
        "HERMES_WEBUI_SERVER_CWD=%h/hermes-webui"
        "PATH=${config.home.profileDirectory}/bin:/run/wrappers/bin:/run/current-system/sw/bin"
      ];
      Restart = "on-failure";
      RestartSec = 5;
      KillMode = "mixed";
      TimeoutStopSec = 30;
    };
  };
}
