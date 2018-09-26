let mapleader = ','
colorscheme desert

" tab style
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4

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
