#!/usr/bin/env bash

source "$HOME/.dotfiles/util.sh"

help() {
  cat << EOF
supported commands:
  install
  install wsl
EOF
}

install() {
  link_file .shell_rc.sh
  link_file .zshrc
  link_file .shell_alias.sh
  link_file .shell_function.sh

  if [[ -d ~/.oh-my-zsh ]]; then
    log "oh-my-zsh already installed"
    exit 0
  fi

  git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh

  if ! command_exist zsh; then
    if is_osx; then
      ensure_command brew

      print_run brew install zsh

    elif is_debian; then
      print_run sudo apt-get install zsh

    elif is_arch; then
      print_run sudo pacman -S zsh

    elif is_centos; then
      print_run sudo yum install zsh
    fi
  fi

  chsh -s /bin/zsh
}

install_wsl() {
  link_file .bashrc

  install
}

run_cmd "$@"

