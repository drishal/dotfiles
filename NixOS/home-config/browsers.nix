{ config, inputs, pkgs, ... }:
{
  programs = {

    # chromium 
    chromium = {
      enable = false;
      # package = pkgs.brave;
      commandLineArgs = [
        "--ignore-gpu-blocklist"
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
        "--force-dark-mode"
        "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder"
        "--disable-features=UseChromeOSDirectVideoDecoder"
        "--use-vulkan"
        "--ozone-platform-hint=auto"
        "--enable-hardware-overlays"
      ];
      extensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
        { id = "nngceckbapebfimnlniiiahkandclblb"; } # bitwarden 
        { id = "lcbjdhceifofjlpecfpeimnnphbcjgnc"; } # xbrowsersync
        # { id = "nbokbjkabcmbfdlbddjidfmibcpneigj"; } #smoothscroll 
      ];
    };

    #qutebrowser
    qutebrowser = {
      enable = true;
    };
  };
}
