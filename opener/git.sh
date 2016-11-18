#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

install() {
  link_file .gitconfig

  if command_exist git; then
    exit 0
  fi

  if [[ $OS = "Darwin" ]]; then
    log xcode-select --install
    xcode-select --install

  elif [[ $OS_ID = "debian" || $OS_ID_LIKE = "debian" ]]; then
    log sudo apt-get install git
    sudo apt-get install git

  elif [[ $OS_ID = "arch" || $OS_ID_LIKE = "arch" ]]; then
    log sudo pacman -S git
    sudo pacman -S git

  else
    log "git is required, please install git first"
  fi
}

[[ 0 = $# || "-i" = $1 || "i" = $1 ]] && install && exit 0
exit 1

