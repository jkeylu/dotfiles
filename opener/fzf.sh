#!/usr/bin/env bash

source "$HOME/.dotfiles/util.sh"

help() {
  cat << EOF
supported commands:
  install
EOF
}

install() {
  link_file .fzf.zsh
  link_file .fzf.bash

  check_command fzf

  if is_osx; then
    ensure_command brew

    print_run brew install fzf
  fi
}

run_cmd "$@"

