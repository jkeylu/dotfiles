#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

function install() {
  link_file .tmux.conf

  if ! command_exist tmux; then
    if [[ $os = "Darwin" ]]; then
      command_exist brew || log "brew is not installed" && exit 1
      brew install tmux
      brew install reattach-to-user-namespace

    elif [[ $os_id = "debian" || $os_id_like = "debian" ]]; then
      sudo apt-get install tmux

    elif [[ $os_id = "arch" || $os_id_like = "arch" ]]; then
      sudo pacman -S tmux
    fi
  fi

  if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    log git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    tmux source ~/.tmux.conf
  fi
}

[[ 0 = $# || "-i" = $1 ]] && install && exit 0

