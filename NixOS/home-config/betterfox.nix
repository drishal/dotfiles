{ inputs, ... }:
{
  imports = [ inputs.betterfox.modules.homeManager.betterfox ]; # or inputs.betterfox.homeModules.betterfox

  # In firefox
  programs.firefox = {
    enable = true;
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
