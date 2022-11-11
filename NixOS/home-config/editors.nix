{ config, inputs, pkgs, ... }:
# Editors
{
  programs = {
    # neovim
    neovim = {
      enable = true;
       # package = pkgs.neovim-nightly;
       extraConfig =
         ''
           ${builtins.readFile ../../config/nvim/init.vim }
           lua << EOF
           ${builtins.readFile ../../config/nvim/init.lua}
         '';
       plugins = with pkgs.vimPlugins; [
         vim-addon-nix
         nvim-lspconfig
         nvim-cmp
         cmp-buffer
         cmp-path
         cmp-spell
         dashboard-nvim
         (nvim-treesitter.withPlugins (_: pkgs.tree-sitter.allGrammars))
         # nvim-treesitter
         cmp-treesitter
         orgmode
         onedark-nvim
         catppuccin-nvim
         neoformat
         vim-nix
         cmp-nvim-lsp
         barbar-nvim
         nvim-web-devicons
         vim-airline
         vim-ccls
         vim-airline-themes
         nvim-autopairs
         neorg
         vim-markdown
         rust-tools-nvim
         lspkind-nvim
       ];
      extraPackages = with pkgs; [
        rnix-lsp
        gcc
        vimPlugins.packer-nvim
        ripgrep
        fd
        nodePackages.pyright
        nodePackages.eslint
        ccls
      ];
    };

    micro={
      enable=false;
    };

    # Emacs
    emacs = {
      enable = false;
      package = pkgs.emacsPgtkNativeComp;
      extraPackages = (epkgs: [ epkgs.vterm epkgs.telega]);
    };

  };
}

