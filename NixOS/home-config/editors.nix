{ config, inputs, pkgs, lib, ... }:

# Editors
{
  programs = {
    micro = {
      enable = false;
    };
    helix = {
      enable = true;
    };
    nixvim = {
      enable = true;
      enableMan = true;
      # colorschemes.onedark.enable = true;
      colorschemes.catppuccin = {
        enable = true;
        background.dark = "mocha";
      };
      # colorschemes.base16 = {
      #   enable = true;
      #   colorscheme =
      #     lib.concatMapAttrs (name: value: {
      #       ${name} = "#${value}";
      #     })
      #       config.colorScheme.palette;
      # };
      options = {
        hlsearch = false;
        number = true;
        mouse = "a";
        breakindent = true;
        undofile = true;
        ignorecase = true;
        smartcase = true;
        signcolumn = "yes";
        updatetime = 250;
        timeoutlen = 300;
        completeopt = "menuone,noselect";
        termguicolors = true;
        guifont = "FantasqueSansM Nerd Font:h14";
      };
      extraPackages = with pkgs;[
        vimPlugins.nvim-web-devicons
      ];
      extraPlugins = with pkgs.vimPlugins;[
        orgmode
      ];
      clipboard = {
        register = "unnamedplus";
        providers = {
          wl-copy.enable = true;
          xclip.enable = true;
        };
      };

      #lsp config
      plugins = {
        dashboard = {
          enable = true;
        };
        lsp = {
          enable = true;
          servers = {
            tsserver.enable = true;
            rust-analyzer = {
              enable = true;
              installCargo = false;
              installRustc = false;
            };
            lua-ls.enable = true;
            pyright.enable = true;
          };
        };
        rust-tools.enable = true;
        lsp-format.enable = true;
        luasnip.enable = true;
        cmp_luasnip.enable = true;
        cmp-treesitter.enable = true;
        which-key.enable = true;
        nvim-autopairs.enable = true;
        neorg.enable = true;
        neo-tree.enable = true;
        fugitive.enable = true;
        gitsigns.enable = true;
        treesitter = {
          enable = true;
          #folding = true;
          ensureInstalled = "all";
        };
        barbar = {
          enable = true;
          autoHide = true;
          clickable = true;
        };
        nix.enable = true;
        tmux-navigator.enable = true;
        cmp = {
          enable = true;
          autoEnableSources = true;
          settings = {
            mapping = {
              "<Down>" = "cmp.mapping.select_next_item()";
              "<Up>" = "cmp.mapping.select_prev_item()";
              "<C-d>" = "cmp.mapping.scroll_docs(-4)";
              "<C-f>" = "cmp.mapping.scroll_docs(4)";
              "<C-Space>" = " cmp.mapping.complete {}";
              "<CR>" = "cmp.mapping.confirm({ select = true })";
              "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
              "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
            };
            sources = [
              { name = "nvim_lsp"; }
              { name = "path"; }
              { name = "buffer"; }
              { name = "luasnip"; }
            ];
            snippet.expand = ''
              function(args)
                require "luasnip".lsp_expand(args.body)
              end
            '';
          };
        };
        cmp-nvim-lsp = {
          enable = true;
        };
        lualine = {
          enable = true;
          iconsEnabled = true;
          # theme = "onedark";
          componentSeparators = {
            left = " ";
            right = " ";
          };
          sectionSeparators = {
            left = " ";
            right = " ";
          };
        };

        comment = {
          enable = true;
        };

        telescope = {
          enable = true;
          extensions = {
            fzf-native = {
              enable = true;
              caseMode = "smart_case";
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
      };
    };
  };
}

  # Emacs: just keeping this as a reference if I decide to setup emacs via home manager in the future
  # emacs = {
  #   enable = true;
  #   package = pkgs.emacs-pgtk;
  #   extraPackages = epkgs: with epkgs; [
  #     treesit-grammars.with-all-grammars
  #     vterm
  #     telega
  #   ];
  # };
