#!/usr/bin/env bash

source "$HOME/.dotfiles/util.sh"

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

run_cmd "$@"

