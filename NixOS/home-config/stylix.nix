{
config,
inputs,
pkgs,
...
}:

{
  stylix = {
    targets = {
      emacs.enable = false;
      neovim.enable = false;
      nixvim.enable = false;
    };
  };
}    