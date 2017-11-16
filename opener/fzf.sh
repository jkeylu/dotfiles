#!/usr/bin/env bash

source "$HOME/.dotfiles/util.sh"

help() {
  cat << EOF
supported commands:
  install
EOF
}

install() {
  link_file .fzf.zsh

  if [[ $OS = "Darwin" ]]; then
    command_exist brew || (log "brew is not installed" && exit 1)
    brew install fzf
  fi
}

run_cmd "$@"

