#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

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

cmd="$(join_by _ "$@")"
if [[ -n $cmd ]]; then
  "$cmd"
else
  help
fi

