#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

help() {
  cat << EOF
supported commands:
  install
EOF
}

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

cmd="$(join_by _ "$@")"
if [[ -n $cmd ]]; then
  "$cmd"
else
  help
fi

