#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

install() {
  if [[ -d ~/.nvm ]]; then
    log "nvm already installed"
    exit 0
  fi

  git clone https://github.com/creationix/nvm.git ~/.nvm && cd ~/.nvm && git checkout `git describe --abbrev=0 --tags`
}

[[ 0 = $# || "-i" = $1 || "i" = $1 ]] && install && exit 0
exit 1

