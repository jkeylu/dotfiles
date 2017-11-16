#!/usr/bin/env bash

source "$HOME/.dotfiles/util.sh"

help() {
  cat << EOF
supported commands:
  install
  install lite
EOF
}

install() {
  [[ -d ~/.vim/.git ]] && exit 0

  backup .vim/
  backup .vimrc

  git clone https://github.com/jkeylu/vim.x.git ~/.vim
  bash ~/.vim/install.sh
}

install_lite() {
  link_file .vimrc
}

run_cmd "$@"

