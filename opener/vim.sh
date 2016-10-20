#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

[[ -d ~/.vim/.git ]] && exit 0

backup .vim/
backup .vimrc

git clone https://github.com/jkeylu/vim.x.git ~/.vim
bash ~/.vim/install.sh
