#!/usr/bin/env bash

[[ -e util.sh ]] && source util.sh || source ../util.sh

if [[ -d ~/.nvm ]]; then
  log "nvm already installed"
  exit 0
fi

git clone https://github.com/creationix/nvm.git ~/.nvm && cd ~/.nvm && git checkout `git describe --abbrev=0 --tags`
