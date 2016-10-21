#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

function install() {
  link_file .zshrc
  link_file .shell_alias
  link_file .shell_function

  if [[ -d ~/.oh-my-zsh ]]; then
    log "oh-my-zsh already installed"
    exit 0
  fi

  git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh

  if ! command_exist zsh; then
    if [[ $os = 'Darwin' ]]; then
      if command_exist brew; then
        brew install zsh
      else
        log "brew is not installed"
        exit 1
      fi

    elif [[ $os_id = 'debian' || $os_id_like = 'debian' ]]; then
      sudo apt-get install zsh

    elif [[ $os_id = 'arch' || $os_id_like = 'arch' ]]; then
      sudo pacman -S zsh
    fi
  fi

  chsh -s /bin/zsh
}

[[ 0 = $# || "-i" = $1 ]] && install && exit 0

