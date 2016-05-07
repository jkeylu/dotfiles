#!/usr/bin/env bash

[[ __util__ = 1 ]] || [[ -e util.sh ]] && source util.sh || source ../util.sh

if [[ -d ~/.oh-my-zsh ]]; then
  log "oh-my-zsh already installed"
  exit 0
fi

git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
chsh -s /bin/zsh
