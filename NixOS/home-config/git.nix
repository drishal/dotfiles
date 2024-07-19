{
  config,
  inputs,
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
      extraConfig = {
        core = {
          editor = "nvim";
          excludesFile = "";
        };
      };
    };
  };
}
