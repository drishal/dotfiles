{ config, inputs, pkgs, ... }:
{
  programs = {
    # # git
    git = {
      enable = true;
      userName = "drishal";
      userEmail = "drishalballaney@gmail.com";
      extraConfig = {
        core = {
          editor = "nvim";
          excludesFile = "";
        };
      };
    };
  };
}
