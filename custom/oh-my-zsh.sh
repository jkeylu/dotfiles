#!/usr/bin/env bash

if [[ -d ~/.oh-my-zsh ]]; then
  echo "oh-my-zsh already installed"
  exit 0
fi

git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
chsh -s /bin/zsh
