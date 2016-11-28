let mapleader = ','
colorscheme desert

" tab style
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4

" key map
imap jj <Esc>`^
nmap <leader>nt :Explore<CR>
nmap <leader>q :q<CR>
autocmd FileType netrw nmap q :bd<CR>

