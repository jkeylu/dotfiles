#!/usr/bin/env bash

OS=`uname`
if [[ $OS != 'Darwin' ]]; then
  if [[ -f "/etc/os-release" ]]; then
    OS_ID=`sed -n 's/^ID=\(.*\)$/\1/p' /etc/os-release`
    OS_ID_LIKE=`sed -n 's/^ID_LIKE=\(.*\)$/\1/p' /etc/os-release`

  elif [[ -f "/etc/centos-release" ]]; then
    OS_ID="centos"
    OS_ID_LIKE="redhat"
  fi
fi

log() {
  echo "  ○ $@"
}

if ! command -v git &> /dev/null; then
  if [[ $OS = "Darwin" ]]; then
    log xcode-select --install
    xcode-select --install

  elif [[ $OS_ID = "debian" || $OS_ID_LIKE = "debian" ]]; then
    log sudo apt-get install git
    sudo apt-get install git

  elif [[ $OS_ID = "arch" || $OS_ID_LIKE = "arch" ]]; then
    log sudo pacman -S git
    sudo pacman -S git

  elif [[ $OS_ID = "centos" ]]; then
    log sudo yum install git
    sudo yum install git

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
