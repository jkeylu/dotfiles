#!/usr/bin/env bash

source "$HOME/.dotfiles/util.sh"

help() {
  cat << EOF
supported commands:
  install
EOF
}

install() {
  link_file .tmux.conf

  if ! command_exist tmux; then
    if is_osx; then
      ensure_command brew

      print_run brew install tmux
      print_run brew install reattach-to-user-namespace

    elif is_debian; then
      print_run sudo apt-get install tmux

    elif is_arch; then
      print_run sudo pacman -S tmux

    elif is_centos; then
      print_run sudo yum install tmux
    fi
  fi

  if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    print_run git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    tmux source ~/.tmux.conf
  fi
}

run_cmd "$@"

