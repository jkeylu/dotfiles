#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

link_file "Library/Application Support/Code/User/"

if [[ ! -d "/Applications/Visual Studio Code.app" ]]; then
  open "https://code.visualstudio.com/"
  log "please install vscode first"
  exit 1
fi

