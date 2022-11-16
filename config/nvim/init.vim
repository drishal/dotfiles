set termguicolors
" lua require('plugins')
set cursorline
let g:vim_markdown_folding_disabled = 1
set clipboard+=unnamedplus
" neovide settings
set guifont=FantasqueSansMono\ Nerd\ Font:h16
let g:neovide_cursor_vfx_mode = "railgun"
augroup packer_user_config
  autocmd!
  autocmd BufWritePost plugins.lua source <afile> | PackerCompile
augroup end

source ~/dotfiles/config/nvim/plugins.lua
source ~/dotfiles/config/nvim/init.lua
