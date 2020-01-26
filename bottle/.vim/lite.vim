"
" author: jKey Lu <jkeylu@gmail.com>
"

if !has('nvim')
  unlet! skip_defaults_vim
  source $VIMRUNTIME/defaults.vim
endif

let mapleader = ','
colorscheme desert

" tab style
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4

autocmd FileType markdown set shiftwidth=4 softtabstop=4
autocmd FileType python set shiftwidth=4 softtabstop=4
autocmd FileType javascript set shiftwidth=2 softtabstop=2
autocmd FileType typescript set shiftwidth=4 softtabstop=4
autocmd FileType go set noexpandtab shiftwidth=4 softtabstop=4
autocmd FileType yaml set shiftwidth=2 softtabstop=2

" netrw
let g:netrw_banner = 0    " disable annoying banner
let g:netrw_altv = 1      " open splits to the right
let g:netrw_liststyle = 3 " tree view
autocmd FileType netrw setl bufhidden=delete

" key map
imap jj <Esc>`^
nmap <leader>nt :Explore<CR>
nmap <leader>q :q<CR>
autocmd FileType netrw nmap q :bd<CR>

" vim:ft=vim fdm=marker et ts=4 sw=2 sts=2
