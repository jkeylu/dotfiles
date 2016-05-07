#!/usr/bin/env bash

[[ __util__ = 1 ]] || [[ -e util.sh ]] && source util.sh || source ../util.sh

if command -v brew >/dev/null 2>&1; then
  log "brew already installed"
  exit 0
fi

/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
