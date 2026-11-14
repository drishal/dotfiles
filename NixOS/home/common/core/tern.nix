{
  config,
  lib,
  pkgs,
  ...
}:

# Tern owns ~/.config/tern: it rewrites settings.json atomically and installs
# need a writable plugins dir. So only read-only inputs are managed here: plugin
# links (.path points at the repo checkout) and a seed for a fresh machine.
let
  repo = "${config.home.homeDirectory}/dotfiles";
  ternConfig = "${config.xdg.configHome}/tern";
in
{
  xdg.configFile = {
    "tern/plugins/herdr.path".text = "${repo}/config/tern/plugins/herdr\n";
    "tern/plugins/notop.path".text = "${repo}/config/tern/plugins/notop\n";
  };

  home.activation.ternSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "${ternConfig}/settings.json" ] && [ -f "${repo}/config/tern/settings.json" ]; then
      ${pkgs.coreutils}/bin/mkdir -p "${ternConfig}"
      ${pkgs.coreutils}/bin/cp "${repo}/config/tern/settings.json" "${ternConfig}/settings.json"
    fi
  '';
}
