#!/usr/bin/env bash

source "$HOME/.dotfiles/util.sh"

help() {
  cat << EOF
supported commands:
  install
EOF
}

install() {
  link_file .shell_rc
  link_file .bashrc
  link_file .bash_profile
  link_file .shell_alias
  link_file .shell_function
}

run_cmd "$@"

