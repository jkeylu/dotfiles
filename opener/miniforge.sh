#!/usr/bin/env bash

source "$HOME/.dotfiles/util.sh"

help() {
  cat << EOF
supported commands:
  install
EOF
}

install() {
  check_command conda

  if is_osx; then
    print_run brew install --cask miniforge

  else
    log "please install miniforge"
  fi
}

run_cmd "$@"

