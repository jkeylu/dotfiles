#!/usr/bin/env bash

source "$HOME/.dotfiles/util.sh"

help() {
  cat << EOF
supported commands:
  install
EOF
}

install() {
  if is_link_file ".vim/simple.vim"; then
    log vim is already installed
    exit 0
  fi

  backup .vim/
  link_file .vim/simple.vim
  link_file .vim/lite.vim

  if [[ -e ~/.vimrc ]]; then
    backup ~/.vimrc
  elif [[ -L ~/.vimrc ]]; then
    rm ~/.vimrc
  fi

  log ln -s ~/.vim/simple.vim ~/.vimrc
  ln -s ~/.vim/simple.vim ~/.vimrc
}

run_cmd "$@"

