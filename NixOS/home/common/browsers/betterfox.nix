{ inputs, lib, ... }:
{
  imports = [ inputs.betterfox.modules.homeManager.betterfox ]; # or inputs.betterfox.homeModules.betterfox

  # In firefox
  programs.firefox = {
    enable = true;

    # Custom overrides on top of Betterfox — fixes for stutter with many (20-30+) tabs.
    # These merge into the same user.js Betterfox generates. Keys that Betterfox also
    # sets need lib.mkForce (it writes with plain priority); the rest are untouched by it.
    profiles."nhkf2vcg.default".settings = {
      # Re-enable on-disk cache: Betterfox runs RAM-only (128MB), which thrashes/evicts
      # with lots of tabs and forces re-fetch on tab switch. We're on fast NVMe, so the
      # SSD-wear rationale doesn't apply.
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
      profiles."nhkf2vcg.default"= {
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
