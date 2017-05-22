#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

help() {
  cat << EOF
supported commands:
  install
  update
EOF
}

install() {
  if [[ -d ~/.nvm ]]; then
    log "nvm already installed"
    exit 0
  fi

  git clone https://github.com/creationix/nvm.git ~/.nvm && cd ~/.nvm && git checkout `git describe --abbrev=0 --tags`
}

update() {
  export NVM_DIR="$HOME/.nvm" && (
    git clone https://github.com/creationix/nvm.git "$NVM_DIR"
    cd "$NVM_DIR"
    git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" origin`
  ) && . "$NVM_DIR/nvm.sh"
}

cmd="$(join_by _ "$@")"
if [[ -n $cmd ]]; then
  "$cmd"
else
  help
fi

