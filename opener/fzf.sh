#!/usr/bin/env bash

source "$HOME/.dotfiles/util.sh"

help() {
  cat << EOF
supported commands:
  install
EOF
}

install() {
  check_command fzf

  if is_osx; then
    ensure_command brew

    print_run brew install fzf
  else
    mkdir -p "$HOME/.local"
    cd "$HOME/.local"
    curl -sL https://raw.githubusercontent.com/junegunn/fzf/refs/heads/master/install | bash -s -- --bin
  fi
}

run_cmd "$@"

