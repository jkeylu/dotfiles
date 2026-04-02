#!/usr/bin/env bash

source "$HOME/.dotfiles/util.sh"

help() {
  cat << EOF
supported commands:
  install
EOF
}

install() {
  if is_win; then
    link_file .bashrc_win .bashrc
    link_file .bash_profile
  else
    link_file .bashrc
    link_file .bash_profile
  fi
}

run_cmd "$@"

