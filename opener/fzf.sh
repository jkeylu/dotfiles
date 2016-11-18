#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

install() {
  link_file .fzf.zsh

  if [[ $OS = "Darwin" ]]; then
    command_exist brew || log "brew is not installed" && exit 1
    brew install fzf
  fi
}

[[ 0 = $# || "-i" = $1 || "i" = $1 ]] && install && exit 0
exit 1

