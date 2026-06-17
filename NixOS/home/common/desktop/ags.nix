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

  # Stylix → AGS bridge.
  #
  # The bar's SCSS references GTK named colors (@accent, @bg, …) rather than
  # literal hex, so the palette can hot-swap without recompiling. Here we emit
  # those @define-color rules from the live base16 scheme. app.tsx reads this
  # file at startup and prepends it to the stylesheet.
  #
  # It lives next to (not inside) ~/.config/ags because that directory is an
  # out-of-store symlink to the repo — Home Manager can't write into it.
  # style/_colors.scss references these @base.. names through #{} interpolation,
  # so the palette hot-swaps on a switch without recompiling the SCSS.
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
}
