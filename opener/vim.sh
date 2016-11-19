#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

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

case "$1" in
  -i|--install|i|install)
    [[ -n $2 ]] && $(install_${2}) || install
    ;;
  *)
    echo "nothing to do ..."
    exit 1
esac

exit 0

