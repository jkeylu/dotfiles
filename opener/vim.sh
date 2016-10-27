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
  link_file .vimrc
}

[[ 0 = $# || "-i" = $1 ]] && install && exit 0
[[ "-l" = $1 ]] && install_lite && exit 0

