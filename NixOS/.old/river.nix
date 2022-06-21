final: prev: let
  inherit (prev) callPackage fetchFromGitHub;
in {
  river = let
    riverSession = ''
      [Desktop Entry]
      Name=River
      Comment=An i3-compatible Wayland compositor
      Exec=river
      Type=Application
    '';
  in
    prev.river.overrideAttrs (prevAttrs: rec {
      postInstall = ''
        mkdir -p $out/share/wayland-sessions
        echo "${riverSession}" > $out/share/wayland-sessions/river.desktop
      '';
      passthru.providedSessions = ["river"];
    });
}
