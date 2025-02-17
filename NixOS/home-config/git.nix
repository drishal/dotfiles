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
      signing.format = "openpgp";
      extraConfig = {
        core = {
          editor = "nvim";
        };
      };
    };
  };
}
