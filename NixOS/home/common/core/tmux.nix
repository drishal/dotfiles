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
    baseIndex = 1;
    plugins = with pkgs.tmuxPlugins; [
      sensible
      vim-tmux-navigator
    ];

    extraConfig = ''
      set -gq allow-passthrough on

      # true color passthrough (keeps stylix palette accurate in TUIs)
      set -ag terminal-features ",*:RGB"

      # panes from 1 (windows via baseIndex), keep them gapless after closing
      setw -g pane-base-index 1
      set -g renumber-windows on

      # new splits/windows inherit the current pane's path
      bind '"' split-window -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      # Clipboard: copy to system clipboard via OSC52
      set -g set-clipboard external
      set -ag terminal-features ",*:clipboard:osc52"
      set -ag terminal-overrides ",xterm-256color:clipboard:osc52"
      set -ag terminal-overrides ",tmux-256color:clipboard:osc52"

      # vi copy mode: v/C-v select, Enter/y and mouse drag copy to clipboard
      bind -T copy-mode-vi v send -X begin-selection
      bind -T copy-mode-vi C-v send -X rectangle-toggle
      bind -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel
      bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel
      bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel

      # === Theme (stylix) ===
      set -g status-style "bg=${c.base01},fg=${c.base05}"
      set -g status-left "#[fg=${c.base0D},bold] [#S] "
      set -g status-left-length 40
      set -g status-right "#[fg=${c.base04}] %H:%M #[bg=${c.base0D},fg=${c.base00},bold] #h "
      set -g status-right-length 60

      set -g window-status-format "#[fg=${c.base04}] #I #W "
      set -g window-status-current-format "#[bg=${c.base0D},fg=${c.base00},bold] #I #[bg=${c.base02},fg=${c.base05}] #W "
      set -g window-status-separator ""

      set -g pane-border-style "fg=${c.base02}"
      set -g pane-active-border-style "fg=${c.base0D}"
      set -g message-style "bg=${c.base02},fg=${c.base05}"
      set -g mode-style "bg=${c.base0D},fg=${c.base00}"
    '';
  };
}
