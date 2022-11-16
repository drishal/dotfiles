-- onedark
require('onedark').setup {
    style = 'dark'
}
require('onedark').load()

vim.o.number = true
-- lspconfig
local nvim_lsp = require('lspconfig')
-- require'lspconfig'.rnix.setup{}
local nvim_lsp = require('lspconfig')
local lspkind = require('lspkind')

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
    -- REQUIRED - you must specify a snippet engine
    expand = function(args)
      --vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
      require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
      -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
      -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
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
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expandable() then
        luasnip.expand()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      elseif has_words_before() then
        cmp.complete()
      else
        fallback()
      end
    end, {
      "i",
      "s",
    }),
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
-- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
require('lspconfig')['rnix'].setup {
  capabilities = capabilities
}
require('lspconfig')['pyright'].setup {
  capabilities = capabilities
}

require('lspconfig')['clangd'].setup {
  capabilities = capabilities
}

require('lspconfig')['eslint'].setup {
  capabilities = capabilities,
  filetypes = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "vue",
    "jsx",
    "html"
  },
}

-- require'lspconfig'.html.setup {
--   capabilities = capabilities,
--   cmd = { html_languageserver, "--stdio" },
-- }

-- tree sitter
require('nvim-treesitter.configs').setup {
  highlight = {
    enable = true,
  },
  -- ensure_installed = {"norg"}, 
  indent = {
    enable = true,
  },  
}
-- neorg
-- require('neorg').setup {
--     load = {
--         ["core.defaults"] = {}
--     }
-- }
