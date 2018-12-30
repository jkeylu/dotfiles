#!/usr/bin/env bash

source "$HOME/.dotfiles/util.sh"

help() {
  cat << EOF
supported commands:
  install
EOF
}

install() {
  if ! is_osx; then
    return
  fi

  link_file "Library/Application Support/Code/User/keybindings.json"
  link_file "Library/Application Support/Code/User/settings.json"

  if [[ ! -d "/Applications/Visual Studio Code.app" ]]; then
    open "https://code.visualstudio.com/"
    log "please install vscode first"
  fi
}

run_cmd "$@"

