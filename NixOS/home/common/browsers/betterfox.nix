{ config, inputs, lib, user, ... }:
{
  imports = [ inputs.betterfox.modules.homeManager.betterfox ]; # or inputs.betterfox.homeModules.betterfox

  # In firefox
  programs.firefox = {
    enable = true;
    # Force the XDG path; ~/.mozilla/firefox is still the default below stateVersion 26.05
    configPath = "${config.xdg.configHome}/mozilla/firefox";

    # Overrides for stutter with 20-30+ tabs, merged into Betterfox's user.js.
    # Keys Betterfox also sets need lib.mkForce — it writes with plain priority.
    profiles."${user}.default".settings = {
      # Betterfox's RAM-only 128MB cache evicts and re-fetches on tab switch;
      # the SSD-wear rationale doesn't apply on NVMe.
      "browser.cache.disk.enable" = lib.mkForce true;
      "browser.cache.disk.capacity" = 1048576; # 1 GB

      # Drop the experimental WebRender layer compositor (a stutter/glitch suspect).
      "gfx.webrender.layer-compositor" = false;

      # More content processes = less cross-tab jank when the pool is exceeded under Fission.
      "dom.ipc.processCount" = 32;

      # Serialize tab state less often to avoid periodic hitches with many tabs.
      "browser.sessionstore.interval" = lib.mkForce 120000;
    };

    betterfox = {
      enable = true;
      profiles."${user}.default"= {
        enableAllSections = true;
        settings = {
          smoothfox = {
            natural-smooth-scrolling-v3.enable = true;
          };
          peskyfox = {
            enable = true;
            mozilla-ui.enable = false;
          };
        };
      };
    };
  };
}
