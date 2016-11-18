#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

install() {
  link_file .zshrc
  link_file .shell_alias
  link_file .shell_function

  if [[ -d ~/.oh-my-zsh ]]; then
    log "oh-my-zsh already installed"
    exit 0
  fi

  git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh

  if ! command_exist zsh; then
    if [[ $OS = 'Darwin' ]]; then
      if command_exist brew; then
        log brew install zsh
        brew install zsh
      else
        log "brew is not installed"
        exit 1
      fi

    elif [[ $OS_ID = 'debian' || $OS_ID_LIKE = 'debian' ]]; then
      log sudo apt-get install zsh
      sudo apt-get install zsh

    elif [[ $OS_ID = 'arch' || $OS_ID_LIKE = 'arch' ]]; then
      log sudo pacman -S zsh
      sudo pacman -S zsh
    fi
  fi

  chsh -s /bin/zsh
}

[[ 0 = $# || "-i" = $1 || "i" = $1 ]] && install && exit 0
exit 1

