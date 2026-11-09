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

      # Zen-style vertical tab rail. sidebar.revamp is default-on since FF 136,
      # so it needs no entry here (Firefox clears it as redundant).
      # expand-on-hover overlays the rail on the page instead of reflowing it,
      # and Firefox hides the horizontal tab strip automatically in this mode.
      "sidebar.verticalTabs" = true;
      "sidebar.visibility" = "expand-on-hover";

      # 0 = let GTK draw the title bar (system min/max/close) instead of
      # Firefox's own buttons. Gated on -moz-gtk-csd-available in Firefox.
      "browser.tabs.inTitlebar" = 0;
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
