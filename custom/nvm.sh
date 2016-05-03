#!/usr/bin/env bash

if [[ -d ~/.nvm ]]; then
  echo "nvm already installed"
  exit 0
fi

git clone https://github.com/creationix/nvm.git ~/.nvm && cd ~/.nvm && git checkout `git describe --abbrev=0 --tags`
