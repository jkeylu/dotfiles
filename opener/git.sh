#!/usr/bin/env bash

source "$HOME/.dotfiles/util.sh"

help() {
  cat << EOF
supported commands:
  install
EOF
}

install() {
  link_file .gitconfig

  check_command git

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
}

run_cmd "$@"

