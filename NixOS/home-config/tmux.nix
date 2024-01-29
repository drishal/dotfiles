{ config, inputs, pkgs, ... }:

programs.tmux = {
  enable = true;
  mouse = true;
  plugins = with pkgs; [
    tmuxPlugins.sensible
  ];
};
