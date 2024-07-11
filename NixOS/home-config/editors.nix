{ config
, inputs
, pkgs
, lib
, ...
}:

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
      colorschemes.catppuccin = {
        enable = true;
        settings.background.dark = "mocha";
      };
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
      # colorscheme = "gruvbox-material";
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
      extraPackages = with pkgs; [ vimPlugins.nvim-web-devicons luajitPackages.lua-utils-nvim ];
      extraPlugins = with pkgs.vimPlugins; [
        orgmode
        (gruvbox-material.overrideAttrs (old: {
          src = pkgs.fetchFromGitHub {
            repo = "gruvbox-material";
            owner = "sainnhe";
            rev = "607fac66a5a4418dd9fe1c8fe7d1368099f5bf96";
            sha256 = "sha256-fZInzV3cTAu94/j7hkeWxQhJbtFeuvAjeWrSG0UVv1A=";
          };
        }))
        (pkgs.vimUtils.buildVimPlugin{
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
            dockerls.enable = true;
            nil-ls.enable = true;
          };
        };
        lspkind.enable = true;
        image.enable = true;
        rust-tools.enable = true;
        lsp-format.enable = true;
        luasnip.enable = true;
        cmp_luasnip.enable = true;
        cmp-treesitter.enable = true;
        which-key.enable = true;
        nvim-autopairs.enable = true;
        direnv.enable = true;
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
          settings.ensureInstalled = "all";
          incrementalSelection = {
            enable = true;
          };
          nixvimInjections = true;
        };
        #treesitter-context.enable = true;
        barbar = {
          enable = true;
          settings = {
            clickable = true;
            autoHide = true;
          };
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
              settings = {
                caseMode = "smart_case";
              };
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
#   extrapackages = epkgs: with epkgs; [
#     treesit-grammars.with-all-grammars
#     vterm
#     telega
#   ];
# };
# colorscheme =
#   lib.concatMapAttrs (name: value: {
#     ${name} = "#${value}";
#   })
# config.colorScheme.palette;
#     config.scheme;
