{ config, ... }:

# Catppuccin Mocha for Vesktop, generated from the active stylix palette.
#
# Only the theme file is written here. Vencord keeps its theme list inside
# ~/.config/vesktop/settings/settings.json, which it rewrites at runtime, so
# enabling is a one-time toggle under Vesktop → Settings → Themes (a store
# symlink there would be read-only, and programs.vesktop.vencord.settings
# would take ownership of every plugin setting).
#
# Catppuccin's overlay*/subtext* greys have no base24 slot, so they are fixed.

let
  c = config.lib.stylix.colors;

  css = ''
    /**
     * @name Catppuccin Mocha (stylix)
     * @author drishal
     * @description Catppuccin Mocha for Vesktop, generated from the active stylix palette.
     * @version 1.0.0
     */

    :root {
      --ctp-crust:     #${c.base11};
      --ctp-mantle:    #${c.base01};
      --ctp-base:      #${c.base00};
      --ctp-surface0:  #${c.base02};
      --ctp-surface1:  #${c.base03};
      --ctp-surface2:  #${c.base04};
      --ctp-overlay0:  #6c7086;
      --ctp-overlay1:  #7f849c;
      --ctp-overlay2:  #9399b2;
      --ctp-subtext0:  #a6adc8;
      --ctp-subtext1:  #bac2de;
      --ctp-text:      #${c.base05};
      --ctp-rosewater: #${c.base06};
      --ctp-lavender:  #${c.base07};
      --ctp-red:       #${c.base08};
      --ctp-peach:     #${c.base09};
      --ctp-yellow:    #${c.base0A};
      --ctp-green:     #${c.base0B};
      --ctp-teal:      #${c.base0C};
      --ctp-blue:      #${c.base0D};
      --ctp-mauve:     #${c.base0E};
      --ctp-maroon:    #${c.base12};
      --ctp-sky:       #${c.base15};
      --ctp-sapphire:  #${c.base16};
      --ctp-pink:      #${c.base17};

      /* translucent layers stay tied to the palette */
      --ctp-hover: color-mix(in srgb, var(--ctp-surface0) 45%, transparent);
      --ctp-faint: color-mix(in srgb, var(--ctp-surface0) 30%, transparent);
    }

    :root,
    .theme-dark,
    .theme-darker,
    .theme-midnight {
      /* surfaces — crust (frame) → mantle (sidebars) → base (chat) */
      --bg-overlay-app-frame:         var(--ctp-crust);
      --background-tertiary:          var(--ctp-crust);
      --background-secondary-alt:     var(--ctp-mantle);
      --background-secondary:         var(--ctp-mantle);
      --background-primary:           var(--ctp-base);
      --background-floating:          var(--ctp-mantle);
      --background-floating-secondary: var(--ctp-mantle);
      --background-mobile-primary:    var(--ctp-base);
      --background-mobile-secondary:  var(--ctp-mantle);
      --channeltextarea-background:   var(--ctp-surface0);
      --background-accent:            var(--ctp-surface1);

      /* hover / selected / borders */
      --background-message-hover:      var(--ctp-hover);
      --background-modifier-hover:     var(--ctp-hover);
      --background-modifier-selected:  var(--ctp-surface1);
      --background-modifier-active:    var(--ctp-surface1);
      --background-modifier-accent:    var(--ctp-surface2);
      --background-mentioned:          color-mix(in srgb, var(--ctp-yellow) 10%, transparent);
      --background-mentioned-hover:    color-mix(in srgb, var(--ctp-yellow) 18%, transparent);

      /* 2024 visual-refresh surfaces */
      --background-base-lowest:       var(--ctp-crust);
      --background-base-lower:        var(--ctp-mantle);
      --background-base-low:          color-mix(in srgb, var(--ctp-base) 92%, var(--ctp-crust));
      --background-base:              var(--ctp-base);
      --background-surface-high:      var(--ctp-base);
      --background-surface-higher:    color-mix(in srgb, var(--ctp-surface0) 68%, var(--ctp-base));
      --background-surface-highest:   var(--ctp-surface0);

      /* 2023 base-color tokens */
      --bg-base-darkest:    var(--ctp-crust);
      --bg-base-darker:     var(--ctp-mantle);
      --bg-base-lower:      var(--ctp-mantle);
      --bg-base-low:        var(--ctp-base);
      --bg-base-tertiary:   var(--ctp-crust);
      --bg-base-secondary:  var(--ctp-mantle);
      --bg-base-primary:    var(--ctp-base);
      --bg-surface-overlay:     var(--ctp-mantle);
      --bg-surface-overlay-tmp: var(--ctp-mantle);
      --bg-surface-raised:      var(--ctp-base);
      --bg-surface-higher:      var(--ctp-surface0);
      --bg-surface-high:        var(--ctp-surface0);
      --bg-mod-faint:    var(--ctp-faint);
      --bg-mod-subtle:   var(--ctp-hover);
      --bg-mod-strong:   var(--ctp-surface1);
      --bg-mod-stronger: var(--ctp-surface2);

      /* cards, popouts, inputs */
      --card-primary-bg:   var(--ctp-mantle);
      --card-secondary-bg: var(--ctp-crust);
      --modal-background:  var(--ctp-mantle);
      --modal-footer-background: var(--ctp-crust);
      --input-background:  var(--ctp-surface0);
      --deprecated-card-bg: var(--ctp-mantle);
      --deprecated-quickswitcher-input-background: var(--ctp-surface0);

      /* text */
      --text-normal:   var(--ctp-text);
      --text-default:  var(--ctp-text);
      --text-muted:    var(--ctp-overlay0);
      --text-faint:    var(--ctp-overlay0);
      --text-secondary: var(--ctp-overlay2);
      --text-tertiary:  var(--ctp-overlay1);
      --header-primary:   var(--ctp-text);
      --header-secondary: var(--ctp-subtext1);
      --interactive-normal: var(--ctp-subtext0);
      --interactive-hover:  var(--ctp-text);
      --interactive-active: var(--ctp-text);
      --interactive-muted:  var(--ctp-overlay0);
      --channels-default:   var(--ctp-overlay1);
      --channel-icon:       var(--ctp-overlay2);

      /* links / mentions */
      --text-link: var(--ctp-blue);
      --text-link-low-saturation: var(--ctp-sapphire);
      --mention-foreground: var(--ctp-yellow);
      --mention-background: color-mix(in srgb, var(--ctp-blue) 30%, transparent);

      /* brand ladder — one hue, darkened toward crust */
      --brand-experiment:     var(--ctp-blue);
      --brand-experiment-560: color-mix(in srgb, var(--ctp-blue) 84%, var(--ctp-crust));
      --brand-experiment-600: color-mix(in srgb, var(--ctp-blue) 76%, var(--ctp-crust));
      --brand-500: var(--ctp-blue);
      --brand-530: color-mix(in srgb, var(--ctp-blue) 92%, var(--ctp-crust));
      --brand-560: color-mix(in srgb, var(--ctp-blue) 84%, var(--ctp-crust));
      --brand-600: color-mix(in srgb, var(--ctp-blue) 76%, var(--ctp-crust));
      --brand-630: color-mix(in srgb, var(--ctp-blue) 68%, var(--ctp-crust));
      --brand-700: color-mix(in srgb, var(--ctp-blue) 55%, var(--ctp-crust));
      --brand-800: color-mix(in srgb, var(--ctp-blue) 40%, var(--ctp-crust));
      --button-outline-brand-text: var(--ctp-crust);
      --text-brand: var(--ctp-blue);

      /* presence + status */
      --online:    var(--ctp-green);
      --idle:      var(--ctp-yellow);
      --dnd:       var(--ctp-red);
      --streaming: var(--ctp-mauve);
      --offline:   var(--ctp-overlay0);
      --status-positive: var(--ctp-green);
      --status-positive-background: var(--ctp-green);
      --status-warning:  var(--ctp-yellow);
      --status-danger:   var(--ctp-red);
      --status-danger-background: var(--ctp-red);
      --info-positive-foreground: var(--ctp-green);
      --info-warning-foreground:  var(--ctp-yellow);
      --info-danger-foreground:   var(--ctp-red);
      --text-positive: var(--ctp-green);
      --text-warning:  var(--ctp-yellow);
      --text-danger:   var(--ctp-red);

      /* scrollbar */
      --scrollbar-thin-thumb: var(--ctp-surface2);
      --scrollbar-thin-track: transparent;
      --scrollbar-auto-thumb: var(--ctp-surface2);
      --scrollbar-auto-track: var(--ctp-crust);
      --scrollbar-auto-scrollbar-color-thumb: var(--ctp-surface2);
      --scrollbar-auto-scrollbar-color-track: var(--ctp-crust);

      /* misc */
      --activity-card-background: var(--ctp-crust);
      --deprecated-text-input-bg: var(--ctp-surface0);
      --deprecated-text-input-border: var(--ctp-surface2);
      --spoiler-hidden-background: var(--ctp-surface2);
      --spoiler-revealed-background: color-mix(in srgb, var(--ctp-surface1) 60%, transparent);
      --focus-primary: var(--ctp-blue);
      --redesign-button-default-bg: var(--ctp-surface1);
      --spotify: var(--ctp-green);
    }

    ::selection {
      background: color-mix(in srgb, var(--ctp-blue) 35%, transparent);
      color: var(--ctp-text);
    }

    /* selected channel / nav item */
    .selected_f6f816,
    .modeSelected_f6f816,
    .selected__01b9c,
    [class*="selected"][class*="link"] {
      background-color: var(--ctp-surface1) !important;
    }

    /* server list rail */
    .guilds_a4d4d9,
    nav[class*="guilds"] {
      background-color: var(--ctp-crust);
    }

    /* code blocks */
    code,
    .hljs {
      background-color: var(--ctp-crust) !important;
      color: var(--ctp-text);
      border-color: var(--ctp-surface1) !important;
    }

    /* unread / mention pill */
    .unread_d4be98,
    [class*="numberBadge"],
    [class*="mentionsBar"] {
      background-color: var(--ctp-red) !important;
      color: var(--ctp-crust) !important;
    }

    /* presence dots */
    rect[fill="#23a55a"],
    [class*="status"][fill] {
      fill: var(--ctp-green);
    }
  '';
in
{
  xdg.configFile."vesktop/themes/catppuccin-mocha.theme.css".text = css;
}
