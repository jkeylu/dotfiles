#!/usr/bin/env bash

source "$HOME/.dotfiles/util.sh"

init_work_dir pm2

help() {
  cat << EOF
suported commands:
  install
EOF
}

install() {
  check_command pm2

  ensure_command npm

  npm -g install pm2
}

run_cmd "$@"
