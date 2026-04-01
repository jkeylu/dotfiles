#!/usr/bin/env bash

source "$HOME/.dotfiles/util.sh"

help() {
  cat << EOF
supported commands:
  install
EOF
}

install() {
  if is_osx; then
    link_file .zshrc_darwin .zshrc
  elif is_win; then
    log "Not supported"
    exit 1
  else
    link_file .zshrc_linux .zshrc
  fi

  if [[ -d ~/.oh-my-zsh ]]; then
    log "oh-my-zsh already installed"
    exit 0
  fi

  git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh

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

  if [[ "$SHELL" != "/bin/zsh" ]]; then
    echo "Changing default shell to zsh..."
    chsh -s /bin/zsh
  fi
}

run_cmd "$@"

