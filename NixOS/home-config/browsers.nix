{ config, inputs, pkgs, ... }:
{
  programs = {
    chromium = {
      enable = true;
      package = pkgs.brave;
      commandLineArgs = [
        "--ignore-gpu-blocklist"
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
        "--enable-features=WebUIDarkMode"
        "--force-dark-mode"
        "--disable-gpu-driver-bug-workarounds"
        "--enable-features=VaapiVideoDecoder"
        "--oauth2-client-id=77185425430.apps.googleusercontent.com"
        "--oauth2-client-secret=OTJgUOQcT7lO7GsGZq2G4IlT"
      ];
      extensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
        { id = "nngceckbapebfimnlniiiahkandclblb"; } # bitwarden 
        { id = "lcbjdhceifofjlpecfpeimnnphbcjgnc"; } # xbrowsersync
      ];
    };
  };
}
