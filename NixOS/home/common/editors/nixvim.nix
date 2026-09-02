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
    nixpkgs.config.allowUnfree = true;
    nixpkgs.source = inputs.nixpkgs.outPath;
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
    # colorschemes.kanagawa = {
    #   enable = true;
    #   settings = {
    #     theme = "wave";              # or "dragon" / "lotus"
    #     background = { dark = "wave"; light = "lotus"; };
    #     transparent = false;
    #     dimInactive = true;
    #     commentStyle = { italic = true; };
    #     keywordStyle = { italic = false; bold = true; };
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
      guifont = "${config.stylix.fonts.monospace.name}:h${toString config.stylix.fonts.sizes.terminal}";
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
      friendly-snippets
      # orgmode
      # (gruvbox-material.overrideAttrs (old: {
      #   src = pkgs.fetchFromGitHub {
      #     repo = "gruvbox-material";
      #     owner = "sainnhe";
      #     rev = "4bfc6983abc249c5943a60d8eb3980a3c2ababe1";
      #     sha256 = "sha256-/7h+fV/DtniC2NmXxYmQrMAMMqMogUWZ5q0uiFqAM+k=";
      #   };
      # }))
      (pkgs.vimUtils.buildVimPlugin {
        name = "gruvbox-material";
        src = inputs.gruvbox-material;
      })

      # (pkgs.vimUtils.buildVimPlugin {
      #   name = "palenight";
      #   src = pkgs.fetchFromGitHub {
      #     owner = "alexmozaidze";
      #     repo = "palenight.nvim";
      #     rev = "43445069c058a717183458cb895b68563e91ff22";
      #     sha256 = "sha256-Qa8qUC0oAByYtDoxdZEZTPBM0n6P3WOAn0uL01j0W+k=";
      #   };
      # })
    ];
    clipboard = {
      register = "unnamedplus";
      providers = {
        wl-copy.enable = true;
        xclip.enable = true;
      };
    };
    keymaps = [
      {
        mode = "n";
        key = "<Esc>";
        action = "<cmd>nohlsearch<cr>";
        options.desc = "Clear search highlight";
      }

      # Telescope
      {
        mode = "n";
        key = "<leader>ff";
        action = "<cmd>Telescope find_files<cr>";
        options.desc = "Find files";
      }
      {
        mode = "n";
        key = "<leader>fg";
        action = "<cmd>Telescope live_grep<cr>";
        options.desc = "Live grep";
      }
      {
        mode = "n";
        key = "<leader>fb";
        action = "<cmd>Telescope buffers<cr>";
        options.desc = "Buffers";
      }
      {
        mode = "n";
        key = "<leader>fh";
        action = "<cmd>Telescope help_tags<cr>";
        options.desc = "Help tags";
      }
      {
        mode = "n";
        key = "<leader>fr";
        action = "<cmd>Telescope oldfiles<cr>";
        options.desc = "Recent files";
      }
      {
        mode = "n";
        key = "<leader>fd";
        action = "<cmd>Telescope diagnostics<cr>";
        options.desc = "Diagnostics";
      }

      # Explorer / git
      {
        mode = "n";
        key = "<leader>e";
        action = "<cmd>Neotree toggle<cr>";
        options.desc = "File explorer";
      }
      {
        mode = "n";
        key = "<leader>gg";
        action = "<cmd>LazyGit<cr>";
        options.desc = "Lazygit";
      }
      {
        mode = "n";
        key = "<leader>gb";
        action = "<cmd>Gitsigns blame_line<cr>";
        options.desc = "Blame line";
      }
      {
        mode = "n";
        key = "<leader>gp";
        action = "<cmd>Gitsigns preview_hunk<cr>";
        options.desc = "Preview hunk";
      }
      {
        mode = "n";
        key = "<leader>gs";
        action = "<cmd>Gitsigns stage_hunk<cr>";
        options.desc = "Stage hunk";
      }
      {
        mode = "n";
        key = "]c";
        action = "<cmd>Gitsigns next_hunk<cr>";
        options.desc = "Next hunk";
      }
      {
        mode = "n";
        key = "[c";
        action = "<cmd>Gitsigns prev_hunk<cr>";
        options.desc = "Prev hunk";
      }

      # Buffers (barbar)
      {
        mode = "n";
        key = "<S-h>";
        action = "<cmd>BufferPrevious<cr>";
        options.desc = "Previous buffer";
      }
      {
        mode = "n";
        key = "<S-l>";
        action = "<cmd>BufferNext<cr>";
        options.desc = "Next buffer";
      }
      {
        mode = "n";
        key = "<leader>bd";
        action = "<cmd>BufferClose<cr>";
        options.desc = "Close buffer";
      }
      {
        mode = "n";
        key = "<leader>bp";
        action = "<cmd>BufferPin<cr>";
        options.desc = "Pin buffer";
      }

      # Trouble
      {
        mode = "n";
        key = "<leader>xx";
        action = "<cmd>Trouble diagnostics toggle<cr>";
        options.desc = "Diagnostics (workspace)";
      }
      {
        mode = "n";
        key = "<leader>xX";
        action = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>";
        options.desc = "Diagnostics (buffer)";
      }
      {
        mode = "n";
        key = "<leader>xt";
        action = "<cmd>Trouble todo toggle<cr>";
        options.desc = "Todo list";
      }

      # Format
      {
        mode = [
          "n"
          "v"
        ];
        key = "<leader>cf";
        action.__raw = "function() require('conform').format({ async = true, lsp_format = 'fallback' }) end";
        options.desc = "Format buffer";
      }

      # Flash
      {
        mode = [
          "n"
          "x"
          "o"
        ];
        key = "s";
        action.__raw = "function() require('flash').jump() end";
        options.desc = "Flash jump";
      }
      {
        mode = [
          "n"
          "x"
          "o"
        ];
        key = "S";
        action.__raw = "function() require('flash').treesitter() end";
        options.desc = "Flash treesitter";
      }
    ];
    #lsp config
    plugins = {
      dashboard.enable = true;
      lsp = {
        enable = true;
        inlayHints = true;
        keymaps = {
          silent = true;
          lspBuf = {
            "gd" = "definition";
            "gD" = "declaration";
            "gr" = "references";
            "gI" = "implementation";
            "gy" = "type_definition";
            "K" = "hover";
            "<leader>cr" = "rename";
            "<leader>ca" = "code_action";
          };
          diagnostic = {
            "]d" = "goto_next";
            "[d" = "goto_prev";
            "<leader>cd" = "open_float";
          };
        };
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
          jsonls.enable = true;
        };
      };
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
      conform-nvim = {
        enable = true;
        autoInstall.enable = true;
        settings = {
          format_on_save = {
            timeout_ms = 500;
            lsp_format = "fallback";
          };
          formatters_by_ft = {
            nix = [ "nixfmt" ];
            lua = [ "stylua" ];
            python = [ "ruff_format" ];
            rust = [ "rustfmt" ];
            go = [ "gofmt" ];
            sh = [ "shfmt" ];
            javascript = [ "prettierd" ];
            typescript = [ "prettierd" ];
            javascriptreact = [ "prettierd" ];
            typescriptreact = [ "prettierd" ];
            json = [ "prettierd" ];
            yaml = [ "prettierd" ];
            css = [ "prettierd" ];
            html = [ "prettierd" ];
            markdown = [ "prettierd" ];
          };
        };
      };
      which-key.enable = true;
      nvim-autopairs.enable = true;
      direnv.enable = true;
      web-devicons.enable = true;
      # Makes lua_ls aware of the `vim` global and nvim runtime types.
      lazydev.enable = true;
      trouble.enable = true;
      todo-comments.enable = true;
      flash.enable = true;
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
        nixvimInjections = true;
        # Grammars come from nix, so `ensure_installed` is never used. All 320
        # would be installed by default; this is the set actually edited here.
        grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
          bash
          c
          cpp
          css
          diff
          dockerfile
          fish
          git_config
          git_rebase
          gitcommit
          gitignore
          go
          gomod
          gosum
          html
          hyprlang
          ini
          javascript
          json
          lua
          luadoc
          make
          markdown
          markdown_inline
          nix
          python
          query
          regex
          rust
          scss
          sql
          ssh_config
          toml
          tsx
          typescript
          vim
          vimdoc
          xml
          yaml
        ];
        settings = {
          highlight = {
            enable = true;
            use_languagetree = true;
          };
          incremental_selection = {
            enable = true;
          };
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
          # Hide the tabline when only one buffer is open. `autoHide = true` was
          # silently ignored: barbar wants snake_case, and an int.
          auto_hide = 1;
        };
      };

      mini = {
        enable = true;
        # mockDevIcons = true;
        modules = {
          ai = {
            n_lines = 50;
          };
          # Default `sa`/`sd`/... would shadow flash's `s`, so use a `gs` prefix.
          surround.mappings = {
            add = "gsa";
            delete = "gsd";
            replace = "gsr";
            find = "gsf";
            find_left = "gsF";
            highlight = "gsh";
          };
          splitjoin = { }; # gS toggles a bracketed list one-line <-> multi-line
          align = { }; # ga / gA align into columns
          move = { }; # Alt-hjkl moves line or selection
          trailspace = { };
        };
      };
      nix.enable = true;
      tmux-navigator.enable = true;
      blink-cmp = {
        enable = true;
        settings = {
          keymap = {
            # <CR> accepts, <Tab> walks the list then snippet placeholders.
            preset = "enter";
            "<Tab>" = [
              "select_next"
              "snippet_forward"
              "fallback"
            ];
            "<S-Tab>" = [
              "select_prev"
              "snippet_backward"
              "fallback"
            ];
            "<Down>" = [
              "select_next"
              "fallback"
            ];
            "<Up>" = [
              "select_prev"
              "fallback"
            ];
            "<C-d>" = [
              "scroll_documentation_up"
              "fallback"
            ];
            "<C-f>" = [
              "scroll_documentation_down"
              "fallback"
            ];
            "<C-space>" = [
              "show"
              "show_documentation"
              "hide_documentation"
            ];
            "<C-e>" = [ "hide" ];
          };
          sources.default = [
            "lsp"
            "path"
            "snippets"
            "buffer"
          ];
          completion = {
            list.selection = {
              preselect = false;
              auto_insert = false;
            };
            documentation = {
              auto_show = true;
              auto_show_delay_ms = 200;
              window.border = "rounded";
            };
            menu.border = "rounded";
            ghost_text.enabled = true;
            accept.auto_brackets.enabled = true;
          };
          signature = {
            enabled = true;
            window.border = "rounded";
          };
          appearance.nerd_font_variant = "mono";
        };
      };
      lualine = {
        enable = true;
        settings = {
          icons_enabled = true;
          theme = "gruvbox-material";
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
        settings = {
          bigfile.enabled = true; # disable heavy features on huge files
          quickfile.enabled = true; # render the file before plugins load
          statuscolumn.enabled = true; # fold/sign/number column
          indent.enabled = true; # indent guides + scope
          scope.enabled = true; # scope-aware textobjects/motions
          input.enabled = true; # nicer vim.ui.input
          words.enabled = true; # highlight + navigate LSP references
          notifier.enabled = false; # noice already owns messages
          scroll.enabled = false; # smooth scroll fights terminal repaint
        };
      };
    };
  };
}
