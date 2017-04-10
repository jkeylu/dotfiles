#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

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

cmd="$(join_by _ "$@")"
if [[ -n $cmd ]]; then
  "$cmd"
else
  help
fi

