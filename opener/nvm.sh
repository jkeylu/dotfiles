#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPT_DIR/../util.sh"

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

install() {
  if [[ -d ~/.nvm ]]; then
    log "nvm already installed"
    exit 1
  fi

  export NVM_DIR="$HOME/.nvm" && (
    git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
    cd "$NVM_DIR"
    git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`
  ) && . "$NVM_DIR/nvm.sh"
}

update() {
  if [[ ! -d $NVM_DIR ]]; then
    error "nvm is not installed, please install first"
    exit 1
  fi

  (
    cd "$NVM_DIR"
    git fetch --tags origin
    git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`
  ) && . "$NVM_DIR/nvm.sh"
}

run_cmd "$@"
