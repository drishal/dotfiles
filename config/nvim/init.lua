-- Portable Neovim config ported from NixVim.
-- Drop this file at ~/.config/nvim/init.lua on machines without Nix.

if vim.fn.has("nvim-0.9") == 0 then
  vim.api.nvim_err_writeln("This config needs Neovim 0.9 or newer.")
  return
end

vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true
vim.g.gruvbox_material_background = "hard"
vim.g.gruvbox_material_better_performance = 1

vim.opt.hlsearch = false
vim.opt.number = true
vim.opt.mouse = "a"
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.completeopt = "menu,menuone,noselect"
vim.opt.termguicolors = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.scrolloff = 8
vim.opt.list = true
vim.opt.listchars = { tab = "  ", trail = ".", nbsp = "_" }
vim.opt.inccommand = "split"
vim.opt.cursorline = true

vim.schedule(function()
  vim.opt.clipboard = "unnamedplus"
end)

local function map(mode, lhs, rhs, desc, opts)
  opts = opts or {}
  opts.desc = desc
  vim.keymap.set(mode, lhs, rhs, opts)
end

map({ "n", "v" }, "<Space>", "<Nop>", "Leader", { silent = true })
map("n", "k", "v:count == 0 ? 'gk' : 'k'", "Move up by display line", { expr = true, silent = true })
map("n", "j", "v:count == 0 ? 'gj' : 'j'", "Move down by display line", { expr = true, silent = true })
map("n", "<Esc>", "<cmd>nohlsearch<CR>", "Clear search highlight")
map("n", "[d", vim.diagnostic.goto_prev, "Previous diagnostic")
map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
map("n", "<leader>e", vim.diagnostic.open_float, "Open diagnostic float")
map("n", "<leader>q", vim.diagnostic.setloclist, "Open diagnostic list")
map("t", "<Esc><Esc>", "<C-\\><C-n>", "Exit terminal mode")

vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("portable-nvim-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.diagnostic.config({
  update_in_insert = false,
  severity_sort = true,
  virtual_text = true,
  float = { border = "rounded", source = "if_many" },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },
})

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local uv = vim.uv or vim.loop
if not uv.fs_stat(lazypath) then
  local lazy_repo = "https://github.com/folke/lazy.nvim.git"
  local result = vim.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazy_repo, lazypath }):wait()
  if result.code ~= 0 then
    vim.api.nvim_err_writeln("Failed to install lazy.nvim:\n" .. (result.stderr or result.stdout or "unknown error"))
    return
  end
end
vim.opt.rtp:prepend(lazypath)

local servers = {
  ts_ls = {},
  rust_analyzer = {},
  gopls = {},
  lua_ls = {
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        workspace = {
          checkThirdParty = false,
          library = vim.api.nvim_get_runtime_file("", true),
        },
        diagnostics = { globals = { "vim" } },
        telemetry = { enable = false },
      },
    },
  },
  basedpyright = {},
  dockerls = {},
  nixd = {},
  jsonls = {},
}

local mason_packages = {
  "typescript-language-server",
  "rust-analyzer",
  "gopls",
  "lua-language-server",
  "basedpyright",
  "dockerfile-language-server",
  "nixd",
  "json-lsp",
  "stylua",
  "shfmt",
  "prettierd",
}

require("lazy").setup({
  {
    "sainnhe/gruvbox-material",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("gruvbox-material")
    end,
  },
  { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      delay = 0,
      icons = { mappings = vim.g.have_nerd_font },
      spec = {
        { "<leader>c", group = "[C]ode" },
        { "<leader>d", group = "[D]ocument" },
        { "<leader>g", group = "[G]it" },
        { "<leader>h", group = "Git [H]unk" },
        { "<leader>s", group = "[S]earch" },
        { "<leader>w", group = "[W]orkspace" },
      },
    },
  },
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = vim.fn.executable("make") == 1,
      },
      "nvim-telescope/telescope-ui-select.nvim",
    },
    config = function()
      local telescope = require("telescope")
      local builtin = require("telescope.builtin")
      telescope.setup({
        defaults = {
          mappings = { i = { ["<C-u>"] = false, ["<C-d>"] = false } },
        },
        extensions = {
          ["ui-select"] = { require("telescope.themes").get_dropdown() },
        },
      })
      pcall(telescope.load_extension, "fzf")
      pcall(telescope.load_extension, "ui-select")

      map("n", "<leader>?", builtin.oldfiles, "[?] Find recently opened files")
      map("n", "<leader><space>", builtin.buffers, "[ ] Find existing buffers")
      map("n", "<leader>/", function()
        builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
          winblend = 10,
          previewer = false,
        }))
      end, "[/] Fuzzily search current buffer")
      map("n", "<leader>gf", builtin.git_files, "Search [G]it [F]iles")
      map("n", "<leader>sf", builtin.find_files, "[S]earch [F]iles")
      map("n", "<leader>sh", builtin.help_tags, "[S]earch [H]elp")
      map("n", "<leader>sk", builtin.keymaps, "[S]earch [K]eymaps")
      map("n", "<leader>sw", builtin.grep_string, "[S]earch current [W]ord")
      map("n", "<leader>sg", builtin.live_grep, "[S]earch by [G]rep")
      map("n", "<leader>sd", builtin.diagnostics, "[S]earch [D]iagnostics")
      map("n", "<leader>sr", builtin.resume, "[S]earch [R]esume")
      map("n", "<leader>ss", builtin.builtin, "[S]earch [S]elect Telescope")
      map("n", "<leader>sc", builtin.commands, "[S]earch [C]ommands")
      map("n", "<leader>sn", function()
        builtin.find_files({ cwd = vim.fn.stdpath("config") })
      end, "[S]earch [N]eovim files")
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      ensure_installed = {
        "bash",
        "c",
        "cpp",
        "css",
        "dockerfile",
        "go",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "nix",
        "python",
        "rust",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
      },
      highlight = { enable = true, use_languagetree = true },
      incremental_selection = { enable = true },
      indent = { enable = true },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    opts = {},
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = vim.tbl_keys(servers),
      automatic_installation = true,
    },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = { ensure_installed = mason_packages },
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
      { "j-hui/fidget.nvim", opts = {} },
    },
    config = function()
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("portable-nvim-lsp-attach", { clear = true }),
        callback = function(event)
          local bufnr = event.buf
          local builtin = require("telescope.builtin")
          local function nmap(keys, rhs, desc)
            map("n", keys, rhs, "LSP: " .. desc, { buffer = bufnr })
          end

          nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
          nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
          nmap("gd", builtin.lsp_definitions, "[G]oto [D]efinition")
          nmap("gr", builtin.lsp_references, "[G]oto [R]eferences")
          nmap("gI", builtin.lsp_implementations, "[G]oto [I]mplementation")
          nmap("<leader>D", builtin.lsp_type_definitions, "Type [D]efinition")
          nmap("<leader>ds", builtin.lsp_document_symbols, "[D]ocument [S]ymbols")
          nmap("<leader>ws", builtin.lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")
          nmap("K", vim.lsp.buf.hover, "Hover Documentation")
          nmap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")
          nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
          nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
          nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
          nmap("<leader>wl", function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
          end, "[W]orkspace [L]ist Folders")

          vim.api.nvim_buf_create_user_command(bufnr, "Format", function()
            vim.lsp.buf.format({ async = true })
          end, { desc = "Format current buffer with LSP" })
        end,
      })

      local lspconfig = require("lspconfig")
      local mason_lspconfig = require("mason-lspconfig")
      mason_lspconfig.setup_handlers({
        function(server_name)
          local server = servers[server_name] or {}
          server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
          lspconfig[server_name].setup(server)
        end,
      })
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-nvim-lua",
      "saadparwaiz1/cmp_luasnip",
      {
        "L3MON4D3/LuaSnip",
        build = vim.fn.has("win32") == 0 and vim.fn.executable("make") == 1 and "make install_jsregexp" or nil,
        dependencies = { "rafamadriz/friendly-snippets" },
      },
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()
      luasnip.config.setup({})

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        completion = { completeopt = "menu,menuone,noselect" },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ["<Down>"] = cmp.mapping.select_next_item(),
          ["<Up>"] = cmp.mapping.select_prev_item(),
          ["<C-d>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete({}),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "path" },
          { name = "buffer" },
          { name = "luasnip" },
          { name = "nvim_lua" },
        },
        experimental = { ghost_text = true },
      })
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        icons_enabled = true,
        theme = "gruvbox-material",
        component_separators = { left = " ", right = " " },
        section_separators = { left = " ", right = " " },
      },
    },
  },
  {
    "romgrk/barbar.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    opts = { clickable = true, auto_hide = true },
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<leader>ee", "<cmd>Neotree toggle<CR>", desc = "Toggle file tree" },
      { "<leader>ef", "<cmd>Neotree reveal<CR>", desc = "Reveal file in tree" },
    },
    opts = {
      filesystem = {
        filtered_items = { hide_dotfiles = false, hide_gitignored = false },
      },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "-" },
        changedelete = { text = "~" },
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        map("n", "<leader>hp", gs.preview_hunk, "Preview git hunk", { buffer = bufnr })
        map("n", "<leader>hr", gs.reset_hunk, "Reset git hunk", { buffer = bufnr })
        map("v", "<leader>hr", function()
          gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Reset selected git hunk", { buffer = bufnr })
        map("n", "<leader>hs", gs.stage_hunk, "Stage git hunk", { buffer = bufnr })
        map("v", "<leader>hs", function()
          gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Stage selected git hunk", { buffer = bufnr })
        map("n", "<leader>hb", gs.blame_line, "Blame line", { buffer = bufnr })
      end,
    },
  },
  { "tpope/vim-fugitive", cmd = { "Git", "Gdiffsplit", "Gread", "Gwrite" } },
  {
    "kdheepak/lazygit.nvim",
    cmd = "LazyGit",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>gg", "<cmd>LazyGit<CR>", desc = "LazyGit" },
    },
    cond = vim.fn.executable("lazygit") == 1,
  },
  {
    "numToStr/Comment.nvim",
    keys = { "gc", "gb" },
    opts = {},
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },
  {
    "nvim-mini/mini.nvim",
    version = false,
    config = function()
      require("mini.ai").setup({ n_lines = 500 })
      require("mini.surround").setup()
      require("mini.statusline").setup({ use_icons = vim.g.have_nerd_font })
    end,
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify" },
    opts = {
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
        progress = {
          enabled = true,
          format = "lsp_progress",
          format_done = "lsp_progress_done",
          throttle = 1000 / 30,
          view = "mini",
        },
      },
      cmdline = { view = "cmdline" },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = true,
      },
    },
  },
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      bigfile = { enabled = true },
      dashboard = { enabled = true },
      notifier = { enabled = true },
      quickfile = { enabled = true },
    },
  },
  {
    "direnv/direnv.vim",
    event = { "BufReadPre", "BufNewFile" },
    cond = vim.fn.executable("direnv") == 1,
  },
  {
    "christoomey/vim-tmux-navigator",
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<CR>", desc = "Move focus left" },
      { "<C-j>", "<cmd>TmuxNavigateDown<CR>", desc = "Move focus down" },
      { "<C-k>", "<cmd>TmuxNavigateUp<CR>", desc = "Move focus up" },
      { "<C-l>", "<cmd>TmuxNavigateRight<CR>", desc = "Move focus right" },
    },
  },
  {
    "nvim-orgmode/orgmode",
    event = "VeryLazy",
    ft = { "org" },
    opts = {},
  },
}, {
  install = { colorscheme = { "gruvbox-material", "habamax" } },
  checker = { enabled = true },
  change_detection = { notify = false },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

-- Keep this after lazy setup so nvim-cmp can integrate with autopairs if both loaded.
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyLoad",
  callback = function(event)
    if event.data ~= "nvim-autopairs" then
      return
    end
    local ok_cmp, cmp = pcall(require, "cmp")
    local ok_pairs, cmp_autopairs = pcall(require, "nvim-autopairs.completion.cmp")
    if ok_cmp and ok_pairs then
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end
  end,
})

-- vim: ts=2 sts=2 sw=2 et
