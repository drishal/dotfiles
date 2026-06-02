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
          # Speed up `git status` (and thus the starship prompt) in large repos.
          # fsmonitor: a per-repo daemon watches the FS via inotify so git only
          #   re-checks changed files instead of lstat-ing every tracked file.
          # untrackedCache: caches per-dir untracked-file lists, skipping
          #   unchanged directories on the next scan.
          # No effect on small repos; big win on huge ones (e.g. AutoEq, 75k files).
          fsmonitor = true;
          untrackedCache = true;
          preloadindex = true;
        };
      };
      signing.format = lib.mkDefault "openpgp";
    };
  };
}
