{
  config,
  pkgs,
  ...
}:

let
  c = config.lib.stylix.colors.withHashtag;
in
{
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    mouse = true;
    keyMode = "vi";
    plugins = [ pkgs.tmuxPlugins.sensible ];

    extraConfig = ''
      set -gq allow-passthrough on

      # Clipboard: copy to system clipboard via OSC52
      set -g set-clipboard external
      set -ag terminal-features ",*:clipboard:osc52"
      set -ag terminal-overrides ",xterm-256color:clipboard:osc52"
      set -ag terminal-overrides ",tmux-256color:clipboard:osc52"

      # vi copy mode: Enter/y and mouse drag copy to system clipboard and exit
      bind -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel
      bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel
      bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel

      # === Theme (stylix) ===
      set -g status-style "bg=${c.base01},fg=${c.base05}"
      set -g status-left "#[bg=${c.base0D},fg=${c.base00},bold] #S #[bg=${c.base01},fg=${c.base01}] "
      set -g status-left-length 40
      set -g status-right "#[fg=${c.base04}] %H:%M #[bg=${c.base0D},fg=${c.base00},bold] #h "
      set -g status-right-length 60

      set -g window-status-format "#[fg=${c.base04}] #I:#W "
      set -g window-status-current-format "#[bg=${c.base0D},fg=${c.base00},bold] #I:#W "
      set -g window-status-separator ""

      set -g pane-border-style "fg=${c.base02}"
      set -g pane-active-border-style "fg=${c.base0D}"
      set -g message-style "bg=${c.base02},fg=${c.base05}"
      set -g mode-style "bg=${c.base0D},fg=${c.base00}"
    '';
  };
}
