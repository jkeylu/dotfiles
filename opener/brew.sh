#!/usr/bin/env bash

source "$HOME/.dotfiles/util.sh"

help() {
  cat << EOF
supported commands:
  install
  uninstall
EOF
}

install() {
  if [[ $OS != 'Darwin' ]]; then
    log "os is not macOS"
  fi

  if command_exist brew; then
    log "brew already installed"
    exit 0
  fi

  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

uninstall() {
  if ! command_exist brew; then
    log "brew is not exist"
    exit 0
  fi

  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall)"
}

run_cmd "$@"

