#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

help() {
  cat << EOF
supported commands:
  install
  install wsl
EOF
}

install() {
  if [[ -d ~/.nvm ]]; then
    log "nvm already installed"
    exit 0
  fi

  git clone https://github.com/creationix/nvm.git ~/.nvm && cd ~/.nvm && git checkout `git describe --abbrev=0 --tags`
}

cmd="$(join_by _ "$@")"
if [[ -n $cmd ]]; then
  "$cmd"
else
  help
fi

