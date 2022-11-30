-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
	-- use 'MarcWeber/vim-addon-nix'
	use 'wbthomason/packer.nvim'
	use 'navarasu/onedark.nvim'
	use 'glepnir/dashboard-nvim'
	use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }
	-- airline
	use 'vim-airline/vim-airline'
	use 'vim-airline/vim-airline-themes'
	--lsp plugins
	use 'neovim/nvim-lspconfig'
	use 'hrsh7th/cmp-nvim-lsp'
	use 'hrsh7th/cmp-buffer'
	use 'hrsh7th/cmp-path'
	use 'hrsh7th/cmp-cmdline'
	use 'onsails/lspkind.nvim'
	use 'simrat39/rust-tools.nvim'
	use 'hrsh7th/nvim-cmp'
	use 'mfussenegger/nvim-jdtls'
	use 'joukevandermaas/vim-ember-hbs'
	use({"L3MON4D3/LuaSnip", tag = "v<CurrentMajor>.*"})


	use {
		'nvim-orgmode/orgmode', 
		config = function()
			require('orgmode').setup{}
		end}

		use {
			"nvim-neorg/neorg",
			config = function()
				require('neorg').setup {
					load = {
						["core.defaults"] = {}
					}
				}
			end,
			requires = "nvim-lua/plenary.nvim"
		}

	end)
