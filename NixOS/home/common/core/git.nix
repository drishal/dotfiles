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
          # Speeds up `git status` (and the starship prompt) in large repos: fsmonitor
          # watches via inotify, untrackedCache skips unchanged dirs. Big win on 75k-file repos.
          fsmonitor = true;
          untrackedCache = true;
          preloadindex = true;
        };
      };
      signing.format = lib.mkDefault "openpgp";
    };
  };
}
