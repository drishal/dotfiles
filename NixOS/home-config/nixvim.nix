{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

{
  programs.nixvim = {
    enable = true;
    enableMan = true;
    # colorschemes.onedark.enable = true;
    # colorschemes.tokyonight = {
    #   enable = true;
    #   settings = {
    #     style = "night";
    #   };
    # };
    # colorschemes.gruvbox = {
    #   enable = true ;
    #   settings = {
    #     contrast = "hard";
    #   };
    # };
    # colorschemes.catppuccin = {
    #   enable = true;
    #   settings.background.dark = "mocha";
    # };
    # colorschemes.everforest = {
    #   enable = true;
    #   settings.background = "hard";
    # };
    # colorschemes.gruvbox = {
    #   enable = true;
    # };
    # colorschemes.base16 = {
    #   enable = true;
    #   colorscheme = with config.scheme.withHashtag; {
    #     base00 = "${base00}";
    #     base01 = "${base01}";
    #     base02 = "${base02}";
    #     base03 = "${base03}";
    #     base04 = "${base04}";
    #     base05 = "${base05}";
    #     base06 = "${base06}";
    #     base07 = "${base07}";
    #     base08 = "${base08}";
    #     base09 = "${base09}";
    #     base0A = "${base0A}";
    #     base0B = "${base0B}";
    #     base0C = "${base0C}";
    #     base0D = "${base0D}";
    #     base0E = "${base0E}";
    #     base0F = "${base0F}";
    #   };
    # };
    colorscheme = "gruvbox-material";
    # colorscheme = "palenight";
    opts = {
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
      # mapleader = "<Space>";
    };
    globals = {
      mapleader = " ";
      # gruvbox_material_better_performance = 1;
      gruvbox_material_background = "hard";
    };
    extraPackages = with pkgs; [ luajitPackages.lua-utils-nvim ];
    extraPlugins = with pkgs.vimPlugins; [
      orgmode
      # orgmode
      (gruvbox-material.overrideAttrs (old: {
        src = pkgs.fetchFromGitHub {
          repo = "gruvbox-material";
          owner = "sainnhe";
          rev = "f5f912fbc7cf2d45da6928b792d554f85c7aa89a";
          sha256 = "sha256-r3a0fhRpEqrAE6QQwBV7DmGoT/YSOhDPl5Nk8evNplE=";
        };
      }))
      (pkgs.vimUtils.buildVimPlugin {
        name = "palenight";
        src = pkgs.fetchFromGitHub {
          owner = "alexmozaidze";
          repo = "palenight.nvim";
          rev = "43445069c058a717183458cb895b68563e91ff22";
          sha256 = "sha256-Qa8qUC0oAByYtDoxdZEZTPBM0n6P3WOAn0uL01j0W+k=";
        };
      })
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
      dashboard.enable = true;
      lsp = {
        enable = true;
        servers = {
          ts_ls.enable = true;
          rust_analyzer = {
            enable = true;
            installCargo = false;
            installRustc = false;
          };
          gopls.enable = true;
          lua_ls.enable = true;
          basedpyright.enable = true;
          dockerls.enable = true;
          nixd.enable = true;
        };
      };
      lspkind.enable = true;
      # lazy = {
      #   enable = true;
      #   plugins = with pkgs.vimPlugins; [
      #     # "sainnhe/gruvbox-material"
      #     orgmode
      #   ];
      # };
      image.enable = true;
      # rustaceanvim = {
      #   enable = true;
      # };
      lsp-format.enable = true;
      luasnip.enable = true;
      cmp_luasnip.enable = true;
      cmp-treesitter.enable = true;
      which-key.enable = true;
      nvim-autopairs.enable = true;
      direnv.enable = true;
      web-devicons.enable = true;
      # neorg = {
      #   enable = true;
      #   modules = {
      #     "core.defaults".__empty = null;
      #     "core.concealer" = {
      #       __empty = null;
      #     };
      #     "core.dirman".config.workspaces = {
      #       vault = "~/doc/vault";
      #     };
      #     #"core.tempus".__empty = null; # waiting for nvim 0.10
      #     "core.ui.calendar".__empty = null;
      #     "core.completion".config.engine = "nvim-cmp";
      #     "core.integrations.telescope" = {
      #       __empty = null;
      #     };
      #     "core.integrations.treesitter" = {
      #       __empty = null;
      #     };
      #     "core.integrations.image" = { __empty = null; };
      #     "core.export" = { __empty = null; };
      #     "core.export.markdown" = { __empty = null; };
      #   };
      # };
      neo-tree.enable = true;
      fugitive.enable = true;
      lazygit.enable = true;
      gitsigns.enable = true;
      treesitter = {
        enable = true;
        settings = {
          ensureInstalled = "all";
          highlight = {
            enable = true;
            use_languagetree = true;
          };
          incremental_selection = {
            enable = true;
          };
          nixvimInjections = true;
          indent = {
            enable = true;
          };
        };
      };
      #treesitter-context.enable = true;
      barbar = {
        enable = true;
        settings = {
          clickable = true;
          autoHide = true;
        };
      };

      mini = {
        enable = true;
        # mockDevIcons = true;
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
            { name = "nvim_lua"; }
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
        settings = {
          icons_enabled = true;
          # theme = "onedark";
          component_separators = {
            left = " ";
            right = " ";
          };
          section_separators = {
            left = " ";
            right = " ";
          };
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
            settings = {
              caseMode = "smart_case";
            };
          };
        };
      };
      noice = {
        enable = true;
        settings = {
          lsp = {
            override = {
              "vim.lsp.util.convert_input_to_markdown_lines" = true;
              "vim.lsp.util.stylize_markdown" = true;
              "cmp.entry.get_documentation" = true;
            };
            progress = {
              enabled = true;
              format = "lsp_progress";
              format_done = "lsp_progress_done";
              throttle = 1000 / 30; # frequency to update lsp progress message
              view = "mini";
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
            lsp_doc_border = true; # add a border to hover docs and signature help
          };
        };
      };
      snacks = {
        enable = true;
      };
    };
  };
}
