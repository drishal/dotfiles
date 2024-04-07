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
    terminal = "xterm";
    plugins = with pkgs; [
      tmuxPlugins.sensible
      tmuxPlugins.vim-tmux-navigator
      tmuxPlugins.onedark-theme
    ];
    extraConfig = '''';
  };
}
