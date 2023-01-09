
-- This file can be loaded by calling `lua require('plugins')` from your init.vim
local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()
-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
	-- use 'MarcWeber/vim-addon-nix'
	use 'wbthomason/packer.nvim'
	use 'navarasu/onedark.nvim'
	use 'glepnir/dashboard-nvim'
	use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }
	use {
		'nvim-lualine/lualine.nvim',
		requires = { 'kyazdani42/nvim-web-devicons', opt = true }
	}
	-- airline
	-- use 'vim-airline/vim-airline'
	-- use 'vim-airline/vim-airline-themes'
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
	use { 'nvim-telescope/telescope.nvim', branch = '0.1.x', requires = { 'nvim-lua/plenary.nvim' } }
        use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make', cond = vim.fn.executable 'make' == 1 }
	use 'williamboman/mason.nvim'
	use "williamboman/mason-lspconfig.nvim"
	use 'joukevandermaas/vim-ember-hbs'
	use 'j-hui/fidget.nvim'
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

	if packer_bootstrap then
		require('packer').sync()
	end
	end)
