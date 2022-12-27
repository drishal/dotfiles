" lua require('plugins')
" set cursorline
let g:vim_markdown_folding_disabled = 1
"set clipboard+=unnamedplus
let g:airline_powerline_fonts = 1

" neovide settings
set guifont=FantasqueSansMono\ Nerd\ Font:h8
let g:neovide_cursor_vfx_mode = "railgun"
augroup packer_user_config
  autocmd!
  autocmd BufWritePost plugins.lua source <afile> | PackerCompile
augroup end


" sourcing the files
source ~/dotfiles/config/nvim/plugins.lua
source ~/dotfiles/config/nvim/init.lua

au BufReadPost *.hbs set syntax=html
