#!/usr/bin/env bash

is_osx() {
  [[ `uname` =~ "Darwin" ]]
}
is_debian() {
  [[ -f "/etc/os-release" ]] && grep -q "debian" /etc/os-release
}
is_ubuntu() {
  [[ -f "/etc/os-release" ]] && grep -q "ubuntu" /etc/os-release
}
is_arch() {
  [[ -f "/etc/os-release" ]] && grep -q "arch" /etc/os-release
}
is_centos() {
  [[ -f "/etc/centos-release" ]]
}

log() {
  echo "  ○ $@"
}

print_run() {
  log "$@"
  "$@"
}

if ! command -v git &> /dev/null; then
  if is_osx; then
    print_run xcode-select --install

  elif is_debian; then
    print_run sudo apt-get install git

  elif is_arch; then
    print_run sudo pacman -S git

  elif is_centos; then
    print_run sudo yum install git

  else
    log "git is required, please install git first"
  fi
fi

if [[ -d ~/.dotfiles ]]; then
  log "dotfiles is already installed"

elif [[ $1 = "--ssh" ]]; then
  print_run git clone git@github.com:jkeylu/dotfiles.git ~/.dotfiles

else
  print_run git clone https://github.com/jkeylu/dotfiles.git ~/.dotfiles
fi

log ~/.dotfiles/biu.sh -h
bash ~/.dotfiles/biu.sh -h
