{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  agsPkgs = inputs.ags.packages.${pkgs.stdenv.hostPlatform.system};
  c = config.lib.stylix.colors;

  # Stylix → AGS bridge: emits @define-color rules that _colors.scss references
  # through #{}, so the palette hot-swaps without recompiling the SCSS.
  # Lives next to ~/.config/ags — that dir is an out-of-store symlink HM can't write into.
  stylixCss = ''
    @define-color base00 #${c.base00};
    @define-color base01 #${c.base01};
    @define-color base02 #${c.base02};
    @define-color base03 #${c.base03};
    @define-color base04 #${c.base04};
    @define-color base05 #${c.base05};
    @define-color base06 #${c.base06};
    @define-color base07 #${c.base07};
    @define-color base08 #${c.base08};
    @define-color base09 #${c.base09};
    @define-color base0A #${c.base0A};
    @define-color base0B #${c.base0B};
    @define-color base0C #${c.base0C};
    @define-color base0D #${c.base0D};
    @define-color base0E #${c.base0E};
    @define-color base0F #${c.base0F};
  '';

  # GTK CSS has no font variables, so _colors.scss leaves AGS_FONT_SANS/MONO
  # sentinels that app.tsx swaps for the live Stylix families at startup.
  fontSans = config.stylix.fonts.sansSerif.name;
  fontMono = config.stylix.fonts.monospace.name;
  fontsJson = builtins.toJSON {
    sans = ''"${fontSans}", "${fontMono}", sans-serif'';
    mono = ''"${fontMono}", monospace'';
  };
in
{
  imports = [ inputs.ags.homeManagerModules.default ];

  programs.ags = {
    enable = true;

    # Live-editable: symlink the repo config to ~/.config/ags so edits take
    # effect on the next `ags run` without a Home Manager rebuild.
    configDir = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/config/ags";

    # Astal libraries + CLI tools the bar shells out to, added to the gjs
    # runtime (typelibs + PATH) without polluting the home environment.
    extraPackages =
      (with agsPkgs; [
        tray
        hyprland
        wireplumber
        network
        battery
        notifd
        powerprofiles
        apps
        bluetooth
        mpris
      ])
      ++ (with pkgs; [
        cliphist
        wl-clipboard
        brightnessctl # backlight slider
        networkmanagerapplet # nm-connection-editor (network tile/module)
        pavucontrol # audio settings (dashboard cog)
        util-linux # rfkill (airplane tile)
      ]);
  };

  xdg.configFile."ags-stylix.css".text = stylixCss;
  xdg.configFile."ags-fonts.json".text = fontsJson;
}
