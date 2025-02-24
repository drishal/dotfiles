{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  programs = {
    # git
    git = {
      enable = true;
      lfs.enable = true;
      userName = "drishal";
      userEmail = "drishalballaney@gmail.com";
      signing.format = lib.mkDefault "openpgp";
      extraConfig = {
        core = {
          editor = "nvim";
        };
      };
    };
  };
}
