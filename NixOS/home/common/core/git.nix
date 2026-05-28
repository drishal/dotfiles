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
      settings = {
        user.name = "drishal";
        user.email = "drishalballaney@gmail.com";
        core = {
          editor = "nvim";
        };
      };
      signing.format = lib.mkDefault "openpgp";
    };
  };
}
