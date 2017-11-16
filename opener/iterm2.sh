#!/usr/bin/env bash

source "$HOME/.dotfiles/util.sh"

help() {
  cat << EOF
supported commands:
  install
EOF
}

install() {
  link_file .config/iTerm2/
}

run_cmd "$@"

