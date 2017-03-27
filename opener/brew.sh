#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

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

case "$1" in
  -i|--install|i|install)
    install
    ;;
  -u|--uninstall|u|uninstall)
    uninstall
    ;;
  *)
    echo "nothing to do ..."
    exit 1
esac

exit 0

