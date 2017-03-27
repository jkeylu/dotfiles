#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

install() {
  link_file .tmux.conf

  if ! command_exist tmux; then
    if [[ $OS = "Darwin" ]]; then
      command_exist brew || (log "brew is not installed" && exit 1)
      brew install tmux
      brew install reattach-to-user-namespace

    elif [[ $OS_ID = "debian" || $OS_ID_LIKE = "debian" ]]; then
      sudo apt-get install tmux

    elif [[ $OS_ID = "arch" || $OS_ID_LIKE = "arch" ]]; then
      sudo pacman -S tmux
    fi
  fi

  if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    log git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    tmux source ~/.tmux.conf
  fi
}

[[ 0 = $# || "-i" = $1 || "i" = $1 ]] && install && exit 0
exit 1

