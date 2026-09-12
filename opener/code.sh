#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPT_DIR/../util.sh"

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
