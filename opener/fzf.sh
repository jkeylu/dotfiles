#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

link_file .fzf.zsh

if [[ $os = "Darwin" ]]; then
  command_exist brew || log "brew is not installed" && exit 1
  brew install fzf
fi
