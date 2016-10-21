#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

function install() {
  link_file .gitconfig

  if command_exist git; then
    exit 0
  fi

  if [[ $os = "Darwin" ]]; then
    log xcode-select --install
    xcode-select --install

  elif [[ $os_id = "debian" || $os_id_like = "debian" ]]; then
    log sudo apt-get install git
    sudo apt-get install git

  elif [[ $os_id = "arch" || $os_id_like = "arch" ]]; then
    log sudo pacman -S git
    sudo pacman -S git

  else
    log "git is required, please install git first"
  fi
}

[[ 0 = $# || "-i" = $1 ]] && install && exit 0

