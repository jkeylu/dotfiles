#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

function install() {
  [[ -d ~/.vim/.git ]] && exit 0

  backup .vim/
  backup .vimrc

  git clone https://github.com/jkeylu/vim.x.git ~/.vim
  bash ~/.vim/install.sh
}

function install_lite() {
  cat > ~/.vimrc <<EOF
let mapleader = ','
colorscheme desert
imap jj <Esc>`^
nmap <leader>nt :Explore<CR>
nmap <leader>q :bd<CR>
EOF
}

[[ 0 = $# || "-i" = $1 ]] && install && exit 0
[[ "-l" = $1 ]] && install_lite && exit 0

