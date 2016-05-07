#!/usr/bin/env bash

[[ -e util.sh ]] && source util.sh || source ../util.sh

if [[ -d ~/.oh-my-zsh ]]; then
  log "oh-my-zsh already installed"
  exit 0
fi

git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
chsh -s /bin/zsh
