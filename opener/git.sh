#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

link_file .gitconfig

if command_exist git; then
  exit 0
fi

if [[ $os = "Darwin" ]]; then
  xcode-select --install

elif [[ $os_id = "debian" || $os_id_like = "debian" ]]; then
  sudo apt-get install git

elif [[ $os_id = "arch" || $os_id_like = "arch" ]]; then
  sudo pacman -S git
fi
