#!/usr/bin/env bash

[[ __util__ = 1 ]] || [[ -e util.sh ]] && source util.sh || source ../util.sh

[[ -d ~/.vim/.git ]] && exit 0

backup .vim/
backup .vimrc

git clone https://github.com/jkeylu/vim.x.git ~/.vim
bash ~/.vim/install.sh
