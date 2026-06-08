{
  config,
  inputs,
  pkgs,
  system,
  ...
}:

let
  colors = config.lib.stylix.colors;
  powerkitThemePath = "${config.xdg.configHome}/tmux/powerkit-stylix-theme.sh";
in
{
  # ─────────────────────────────────────────────────────────────
  #  Powerkit theme · colors derived from the active Stylix scheme
  # ─────────────────────────────────────────────────────────────
  home.file.".config/tmux/powerkit-stylix-theme.sh".text = ''
    #!/usr/bin/env bash

    declare -gA THEME_COLORS=(
      [background]="#${colors.base00}"

      # Status bar
      [statusbar-bg]="#${colors.base00}"
      [statusbar-fg]="#${colors.base05}"

      # Session indicator (changes color per mode)
      [session-bg]="#${colors.base0E}"           # magenta (signature accent)
      [session-fg]="#${colors.base00}"
      [session-prefix-bg]="#${colors.base09}"    # orange  · prefix held
      [session-copy-bg]="#${colors.base0C}"      # cyan    · copy mode
      [session-search-bg]="#${colors.base0A}"    # yellow  · search
      [session-command-bg]="#${colors.base0D}"   # blue    · command prompt

      # Windows · powerkit derives the number-badge / name shades automatically
      [window-active-base]="#${colors.base0C}"   # cyan pill for the focused window
      [window-active-style]="bold"
      [window-inactive-base]="#${colors.base0E}" # magenta pill for the rest
      [window-inactive-style]="none"
      [window-activity-style]="italics"
      [window-bell-style]="bold"
      [window-zoomed-bg]="#${colors.base09}"     # orange · zoomed pane

      # Pane borders
      [pane-border-active]="#${colors.base0D}"   # blue
      [pane-border-inactive]="#${colors.base02}"

      # Severity states (semantic plugin/health colors)
      [ok-base]="#${colors.base02}"
      [good-base]="#${colors.base0B}"            # green
      [info-base]="#${colors.base0D}"            # blue
      [warning-base]="#${colors.base0A}"         # yellow
      [error-base]="#${colors.base08}"           # red
      [disabled-base]="#${colors.base03}"

      # Messages
      [message-bg]="#${colors.base0A}"           # yellow command/message line
      [message-fg]="#${colors.base00}"

      # Popups & menus
      [popup-bg]="#${colors.base01}"
      [popup-fg]="#${colors.base05}"
      [popup-border]="#${colors.base0E}"
      [menu-bg]="#${colors.base01}"
      [menu-fg]="#${colors.base05}"
      [menu-selected-bg]="#${colors.base0E}"
      [menu-selected-fg]="#${colors.base00}"
      [menu-border]="#${colors.base0E}"
    )
  '';

  programs.tmux = {
    enable = true;

    mouse = true;
    terminal = "tmux-256color";

    # ───────────────────────────────────────────────────────────
    #  Plugins · TPM is replaced by Home Manager's declarative
    #            plugin management.
    # ───────────────────────────────────────────────────────────
    plugins = with pkgs.tmuxPlugins; [
      sensible

      {
        plugin = inputs.tmux-powerkit.packages.${system}.default;
        extraConfig = ''
          # Theme
          set -g @powerkit_theme "custom"
          set -g @powerkit_theme_variant "stylix"
          set -g @powerkit_custom_theme_path "${powerkitThemePath}"

          # Right-hand modules · each in its own group so it pulls the next
          # color from the rainbow palette below (Catppuccin-like, two-tone pills).
          set -g @powerkit_plugins "group(cpu),group(memory),group(uptime),group(battery)"
          set -g @powerkit_plugin_group_coloring "true"

          # Stylix accent rainbow: blue · magenta · green · yellow · cyan · red.
          # Icons are auto-lightened from these by powerkit for the two-tone look.
          set -g @powerkit_plugin_group_colors "#${colors.base0D},#${colors.base0E},#${colors.base0B},#${colors.base0A},#${colors.base0C},#${colors.base08}"

          # Module icons
          set -g @powerkit_plugin_cpu_icon ""
          set -g @powerkit_plugin_memory_icon ""
          set -g @powerkit_plugin_memory_format "percent"
          set -g @powerkit_plugin_uptime_icon "󰔟"
          set -g @powerkit_plugin_battery_icon "󰁹"
          set -g @powerkit_plugin_battery_icon_charging "󰂄"
          set -g @powerkit_plugin_battery_icon_warning "󰁻"
          set -g @powerkit_plugin_battery_icon_critical "󰁺"

          # Layout & separators
          set -g @powerkit_separator_style "rounded"
          set -g @powerkit_edge_separator_style "rounded:all"
          set -g @powerkit_elements_spacing "false"
          set -g @powerkit_status_order "session,plugins"
          set -g @powerkit_status_position "bottom"
          set -g @powerkit_status_justify "left"
          set -g @powerkit_status_interval "5"
        '';
      }

      vim-tmux-navigator
      yank
      resurrect
      continuum
    ];

    extraConfig = ''
      # ─── Terminal features / passthrough ──────────────────────
      set -gq allow-passthrough on

      # ─── Copy mode (vi-style) ─────────────────────────────────
      setw -g mode-keys vi

      # ─── Clipboard ────────────────────────────────────────────
      # Copy to the system clipboard by default.
      set -g set-clipboard external

      # Enable OSC52 clipboard support in modern terminals.
      set -ag terminal-features ",*:clipboard:osc52"
      set -ag terminal-overrides ",xterm-256color:clipboard:osc52"
      set -ag terminal-overrides ",tmux-256color:clipboard:osc52"

      # Enter / y copy to system clipboard and exit copy mode.
      bind -T copy-mode-vi Enter            send-keys -X copy-pipe-and-cancel
      bind -T copy-mode-vi y                send-keys -X copy-pipe-and-cancel
      bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel

      # ─── Status bar sizing ────────────────────────────────────
      set -g status-left-length 100
      set -g status-right-length 500

      # ─── Session persistence (resurrect + continuum) ──────────
      set -g @continuum-restore "on"
      set -g @continuum-save-interval "10"
    '';
  };
}
