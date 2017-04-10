#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

help() {
  cat << EOF
supported commands:
  install
EOF
}

install() {
  link_file .fzf.zsh

  if [[ $OS = "Darwin" ]]; then
    command_exist brew || (log "brew is not installed" && exit 1)
    brew install fzf
  fi
}

cmd="$(join_by _ "$@")"
if [[ -n $cmd ]]; then
  "$cmd"
else
  help
fi

