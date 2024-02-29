{ config, inputs, pkgs, ... }:
# Editors
{
  programs = {
    micro={
      enable=false;
    };
    # Emacs
    emacs = {
      enable = true;
      package = pkgs.emacs-pgtk;
      extraPackages = (epkgs: [ epkgs.vterm epkgs.telega]);
    };
    helix = {
      enable = true;
    };

    nixvim = {
      enable = true;
      enableMan = true;
      colorschemes.onedark.enable = true;
      extraConfigLua = ''
      -- Set highlight on search
      vim.o.hlsearch = false

      -- Make line numbers default
      vim.wo.number = true

      -- Enable mouse mode
      vim.o.mouse = 'a'

      -- Sync clipboard between OS and Neovim.
      --  Remove this option if you want your OS clipboard to remain independent.
      --  See `:help 'clipboard'`
      vim.o.clipboard = 'unnamedplus'

      -- Enable break indent
      vim.o.breakindent = true

      -- Save undo history
      vim.o.undofile = true
      -- Case-insensitive searching UNLESS \C or capital in search
      vim.o.ignorecase = true
      vim.o.smartcase = true

      -- Keep signcolumn on by default
      vim.wo.signcolumn = 'yes'

      -- Decrease update time
      vim.o.updatetime = 250
      vim.o.timeoutlen = 300

      -- Set completeopt to have a better completion experience
      vim.o.completeopt = 'menuone,noselect'

      -- NOTE: You should make sure your terminal supports this
      vim.o.termguicolors = true
      '';
      extraPackages = with pkgs;[
        vimPlugins.nvim-web-devicons
      ];
      extraPlugins = with pkgs.vimPlugins;[
        orgmode
      ];
      clipboard.register="unnamedplus";
      #lsp config
      plugins = {
        dashboard = {
          enable=true;
        };
        lsp={
          enable = true;
          servers = {
            tsserver.enable=true;
            rust-analyzer = {
              enable = true;
              installCargo = false;
              installRustc = false;
            };
            lua-ls.enable=true;
            rnix-lsp.enable=true;
          };
        };
        luasnip.enable=true;
        cmp_luasnip.enable=true;
        cmp-treesitter.enable=true;
        which-key.enable=true;
        nvim-autopairs.enable=true;
        neorg.enable=true;
        neo-tree.enable=true;

        treesitter = {
          enable=true;
          # folding=true;
        };
        barbar={
          enable=true;
          autoHide=true;
          clickable=true;
        };
        nix.enable=true;
        tmux-navigator.enable=true;
        nvim-cmp = {
          enable = true;
          autoEnableSources = true;
          sources = [
            {name = "nvim_lsp";}
            {name = "path";}
            {name = "buffer";}
            {name = "luasnip";}
          ];
          # snippet.expand = ''
          # function(args)
          #   luasnip.lsp_expand(args.body)
          # end,
          # '';
          snippet.expand="luasnip";
          mapping = {
            "<Down>"="cmp.mapping.select_next_item()";
            "<Up>"="cmp.mapping.select_prev_item()";
            "<C-d>"="cmp.mapping.scroll_docs(-4)";
            "<C-f>"="cmp.mapping.scroll_docs(4)";
            "<C-Space>" =" cmp.mapping.complete {}";
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<Tab>" = {
              action = ''
              function(fallback)
              if cmp.visible() then
              cmp.select_next_item()
              elseif luasnip.expandable() then
              luasnip.expand()
              elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
              elseif check_backspace() then
              fallback()
              else
              fallback()
              end
              end
              '';
              modes = [ "i" "s" ];
            };
          };
        };
        lualine = {
          enable = true;
          iconsEnabled = true;
          theme="onedark";
          componentSeparators = {
            left = " ";
            right = " ";
          };
          sectionSeparators = {
            left = " ";
            right = " ";
          };
        };

        comment-nvim = {
          enable = true;
        };

        telescope = {
          enable = true;
          extensions = {
            fzf-native={
              enable=true;
              caseMode="smart_case";
            };
          };
        };
        noice = {
          enable = true;
          lsp = {
            override = {
              "vim.lsp.util.convert_input_to_markdown_lines" = true;
              "vim.lsp.util.stylize_markdown" = true;
              "cmp.entry.get_documentation" = true;
            };
          };
          cmdline = {
            view = "cmdline";
          };
          presets = {
            bottom_search = true; # use a classic bottom cmdline for search
            command_palette = true; # position the cmdline and popupmenu together
            long_message_to_split = true; # long messages will be sent to a split
            inc_rename = false; # enables an input dialog for inc-rename.nvim
            lsp_doc_border = false; # add a border to hover docs and signature help
          };
        };
        none-ls = {
          enable = true;
        };
      };
    };
  };
}

