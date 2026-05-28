{
config,
inputs,
pkgs,
...
}:
{
  programs.tmux = {
    enable = true;
    mouse = true;
    terminal = "tmux-256color";
    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = catppuccin;
        extraConfig = '' 
         set -g @catppuccin_flavour 'mocha'
         set -g @catppuccin_window_tabs_enabled on
         set -g @catppuccin_date_time "%H:%M"
         set -g @catppuccin_window_left_separator ""
         set -g @catppuccin_window_right_separator " "
         set -g @catppuccin_window_middle_separator " █"
         set -g @catppuccin_window_number_position "right"
         set -g @catppuccin_window_default_fill "number"
         set -g @catppuccin_window_default_text "#W"
         set -g @catppuccin_window_current_fill "number"
         set -g @catppuccin_window_current_text "#W"
         set -g @catppuccin_status_modules_right "directory user host session"
         set -g @catppuccin_status_left_separator  " "
         set -g @catppuccin_status_right_separator ""
         set -g @catppuccin_status_fill "icon"
         set -g @catppuccin_status_connect_separator "no"
         set -g @catppuccin_directory_text "#{pane_current_path}"
        '';
      }
      vim-tmux-navigator
    ];
  };
}
