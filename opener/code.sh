#!/usr/bin/env bash

source "$HOME/.dotfiles/util.sh"

help() {
  cat << EOF
supported commands:
  install
EOF
}

install() {
  link_file "Library/Application Support/Code/User/"

  if [[ ! -d "/Applications/Visual Studio Code.app" ]]; then
    open "https://code.visualstudio.com/"
    log "please install vscode first"
    exit 1
  fi
}

run_cmd "$@"

