#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

if [[ $os != 'Darwin' ]]; then
  log "os is not macOS"
fi

if command_exist brew; then
  log "brew already installed"
  exit 0
fi

/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

