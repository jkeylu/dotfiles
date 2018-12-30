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
  if ! is_osx; then
    log "brew can only be installed on macOS"
  fi

  check_command brew

  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

uninstall() {
  ensure_command brew

  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall)"
}

run_cmd "$@"

