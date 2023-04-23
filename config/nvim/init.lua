-- onedark
require('onedark').setup {
    style = 'dark'
}
require('onedark').load()

-- some color settings
vim.o.termguicolors = true
vim.g.vim_markdown_folding_disabled = 1
vim.o.number = true
vim.o.cursorline = true
vim.o.clipboard = "unnamedplus"

-- disable auto comments

-- dashboard 

require('dashboard').setup {

}

--tabnine 
require('tabnine').setup({
  disable_auto_comment=true, 
  accept_keymap="<Tab>",
  dismiss_keymap = "<C-]>",
  debounce_ms = 800,
  suggestion_color = {gui = "#808080", cterm = 244},
  exclude_filetypes = {"TelescopePrompt"}
})

-- leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
-- lspconfig
local nvim_lsp = require('lspconfig')
-- require'lspconfig'.rnix.setup{}
local nvim_lsp = require('lspconfig')
local lspkind = require('lspkind')

nvim_lsp.emmet_ls.setup({
    -- on_attach = on_attach,
    capabilities = capabilities,
    filetypes = { 'html', 'typescriptreact', 'javascriptreact', 'css', 'sass', 'scss', 'less', 'lua'},
    init_options = {
      html = {
        options = {
          -- For possible options, see: https://github.com/emmetio/emmet/blob/master/src/config.ts#L79-L267
          ["bem.enabled"] = true,
        },
      },
    }
})
-- [[ Configure Telescope ]]
-- See `:help telescope` and `:help telescope.setup()`
require('telescope').setup {
    defaults = {
        mappings = {
            i = {
                ['<C-u>'] = false,
                ['<C-d>'] = false,
            },
        },
    },
}

-- Enable telescope fzf native, if installed
pcall(require('telescope').load_extension, 'fzf')

-- See `:help telescope.builtin`
vim.keymap.set('n', '<leader>?', require('telescope.builtin').oldfiles, { desc = '[?] Find recently opened files' })
vim.keymap.set('n', '<leader><space>', require('telescope.builtin').buffers, { desc = '[ ] Find existing buffers' })
vim.keymap.set('n', '<leader>/', function()
    -- You can pass additional configuration to telescope to change theme, layout, etc.
    require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
        winblend = 10,
        previewer = false,
    })
end, { desc = '[/] Fuzzily search in current buffer]' })

vim.keymap.set('n', '<leader>sf', require('telescope.builtin').find_files, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>sh', require('telescope.builtin').help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sw', require('telescope.builtin').grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', require('telescope.builtin').live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', require('telescope.builtin').diagnostics, { desc = '[S]earch [D]iagnostics' })

-- lualine
require('lualine').setup {
    options = {
        icons_enabled = true,
        theme = 'onedark',
        component_separators = { left = ' ', right = ' '},
        section_separators = { left = ' ', right = ' '},
        disabled_filetypes = {
            statusline = {},
            winbar = {},
        },
        ignore_focus = {},
        always_divide_middle = true,
        globalstatus = false,
        refresh = {
            statusline = 1000,
            tabline = 1000,
            winbar = 1000,
        }
    },
    sections = {
        lualine_a = {'mode'},
        lualine_b = {'branch', 'diff', 'diagnostics'},
        lualine_c = {'filename'},
        lualine_x = {'encoding', 'fileformat', 'filetype'},
        lualine_y = {'progress'},
        lualine_z = {'location'}
    },
    inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {'filename'},
        lualine_x = {'location'},
        lualine_y = {},
        lualine_z = {}
    },
    tabline = {
        lualine_a = {},
        lualine_b = {'branch'},
        lualine_c = {'filename'},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {}
    },
    winbar = {},
    inactive_winbar = {},
    extensions = {}
}
--cmp
-- Setup nvim-cmp.
--
--rust
require('rust-tools').setup({})


local cmp = require'cmp'
local cmp_kinds = {
    Class		= " ",
    Color		= " ",
    Constant	= " ",
    Constructor	= " ",
    Enum		= " ",
    EnumMember	= " ",
    Event		= "a ",
    Field		= "ﰠ ",
    File		= " ",
    Folder	= " ",
    Function	= " ",
    Interface	= " ",
    Keyword	= " ",
    Method	= " ",
    Module	= " ",
    Operator	= " ",
    Property	= " ",
    Reference	= " ",
    Snippet	= " ",
    Struct	= "פּ ",
    Text		= " ",
    TypeParameter = " ",
    Unit		= " ",
    Value		= " ",
    Variable	= " ",
}

cmp.setup({
    snippet = {
        expand = function(args)
            require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
        end,
    },

    formatting = {
        -- format = function(_, vim_item)
        --   vim_item.kind = (cmp_kinds[vim_item.kind] or '') .. vim_item.kind
        --   return vim_item
        -- end,
        format = lspkind.cmp_format({
            mode = "symbol_text",
            menu = ({
                nvim_lsp = "[LSP]",
                ultisnips = "[US]",
                nvim_lua = "[Lua]",
                path = "[Path]",
                buffer = "[Buffer]",
                emoji = "[Emoji]",
                omni = "[Omni]",
            }),
        }),

    },

    mapping = {
        ["<Up>"] = cmp.mapping.select_prev_item(),
        --["<ESC>"] = { "<cmd> noh <CR>", "no highlight" },
        ["<Down>"] = cmp.mapping.select_next_item(),
        ["<C-p>"] = cmp.mapping.select_prev_item(),
        ["<C-n>"] = cmp.mapping.select_next_item(),
        ["<C-k>"] = cmp.mapping.select_prev_item(),
        ["<C-j>"] = cmp.mapping.select_next_item(),
        ["<C-d>"] = cmp.mapping(cmp.mapping.scroll_docs(-1), { "i", "c" }),
        ["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(1), { "i", "c" }),
        ["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
        ["<C-y>"] = cmp.config.disable,
        ["<C-e>"] = cmp.mapping {
            i = cmp.mapping.abort(),
            c = cmp.mapping.close(),
        },
        ["<CR>"] = cmp.mapping.confirm { select = false },
--        ["<Tab>"] = cmp.mapping(function(fallback)
--            if cmp.visible() then
--                cmp.select_next_item()
--            elseif luasnip.expandable() then
--                luasnip.expand()
--            elseif luasnip.expand_or_jumpable() then
--                luasnip.expand_or_jump()
--            elseif has_words_before() then
--                cmp.complete()
--            else
--                fallback()
--            end
--        end, {
--                "i",
--                "s",
--            }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, {
                "i",
                "s",
            }),
    },

    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'vsnip' }, -- For vsnip users.
        { name = 'orgmode' },
        -- { name = 'luasnip' }, -- For luasnip users.
        -- { name = 'ultisnips' }, -- For ultisnips users.
        -- { name = 'snippy' }, -- For snippy users.
    }, {
            { name = 'buffer' },
        })
})

-- Set configuration for specific filetype.
cmp.setup.filetype('gitcommit', {
    sources = cmp.config.sources({
        { name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it.
    }, {
            { name = 'buffer' },
        })
})

-- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline('/', {
    sources = {
        { name = 'buffer' }
    }
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
    sources = cmp.config.sources({
        { name = 'path' }
    }, {
            { name = 'cmdline' }
        })
})

-- Setup lspconfig.
local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())
require("mason").setup()
local servers = { 'clangd', 'rust_analyzer', 'pyright', 'tsserver', 'jdtls', 'rnix', 'jsonls'}
require("mason-lspconfig").setup({
    ensure_installed = servers,
    -- automatic_installation = true
})
-- nvim-cmp supports additional completion capabilities
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

for _, lsp in ipairs(servers) do
    require('lspconfig')[lsp].setup {
        on_attach = on_attach,
        capabilities = capabilities,
    }
end
require('fidget').setup()

-- tree sitter
require('nvim-treesitter.configs').setup {
    highlight = {
        enable = true,
        -- Required for spellcheck, some LaTex highlights and
        -- code block highlights that do not have ts grammar
        -- additional_vim_regex_highlighting = {'org'},
    },
    -- ensure_installed = {'org'}, -- Or run :TSUpdate org
    -- ensure_installed = {"norg"}, 
    indent = {
        enable = true,
    },  
    ensure_installed = {"bash", "nix", "lua", "html", "css", "javascript", "org", "norg", "markdown", "toml", "typescript", "regex" },
}
--org mode
require('orgmode').setup_ts_grammar()
-- vim: ts=2 sts=2 sw=2 et

-- some keybinds 
-- pressing escape to hide highlights
vim.api.nvim_set_keymap('n', '<Esc>', ':noh<CR>', { noremap = true })
--vim.api.nvim_set_keymap('n', '<Esc>', ':silent! noh:echo ""<CR>', { noremap = true })

-- noice.nvim
require("noice").setup({
    lsp = {
        -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
        override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true,
        },
    },
    cmdline = {
        view = "cmdline",
    },
    -- you can enable a preset for easier configuration
    presets = {
        bottom_search = true, -- use a classic bottom cmdline for search
        command_palette = true, -- position the cmdline and popupmenu together
        long_message_to_split = true, -- long messages will be sent to a split
        inc_rename = false, -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = false, -- add a border to hover docs and signature help
    },
})

--indentation settings
-- Use spaces instead of tabs
vim.o.expandtab = true

-- Number of spaces to use for a tab character
vim.o.tabstop = 4

-- Number of spaces to use for each level of indentation
vim.o.shiftwidth = 4

-- Use shiftwidth value for 'tabstop'
vim.o.softtabstop = -1

-- Automatically indent new lines with same number of spaces as previous line
vim.o.autoindent = true

-- Automatically adjust indentation based on context
vim.o.smartindent = true
