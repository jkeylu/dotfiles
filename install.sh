#!/usr/bin/env bash

os=`uname`
if [[ $os != 'Darwin' ]]; then
  os_id=`sed -n 's/^ID=\(.*\)$/\1/p' /etc/os-release`
  os_id_like=`sed -n 's/^ID_LIKE=\(.*\)$/\1/p' /etc/os-release`
fi

function log() {
  echo "  ○ $@"
}

if ! command -v git &> /dev/null; then
  if [[ $os = "Darwin" ]]; then
    log xcode-select --install
    xcode-select --install

  elif [[ $os_id = "debian" || $os_id_like = "debian" ]]; then
    log sudo apt-get install git
    sudo apt-get install git

  elif [[ $os_id = "arch" || $os_id_like = "arch" ]]; then
    log sudo pacman -S git
    sudo pacman -S git

  else
    log "git is required, please install git first"
  fi
fi

if [[ -d ~/.dotfiles ]]; then
  log "dotfiles is already installed"

elif [[ $1 = "--ssh" ]]; then
  log git clone git@github.com:jkeylu/dotfiles.git ~/.dotfiles
  git clone git@github.com:jkeylu/dotfiles.git ~/.dotfiles

else
  log git clone https://github.com/jkeylu/dotfiles.git ~/.dotfiles
  git clone https://github.com/jkeylu/dotfiles.git ~/.dotfiles
fi

log ~/.dotfiles/biu.sh -h
bash ~/.dotfiles/biu.sh -h
