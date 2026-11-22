{ ... }:

{
  # rex server install pins ExecStart to a store path that GC drops after a
  # flake bump; the unit would listen but never start a server.
  xdg.configFile."systemd/user/rex.service.d/10-profile-exec.conf".text = ''
    [Service]
    ExecStart=
    ExecStart=/run/current-system/sw/bin/rex server run --log-format text
  '';
}
