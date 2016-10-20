#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

if [[ $os = "Darwin" ]]; then
  if ! command_exist tmux; then
    command_exist brew || log "brew is not installed" && exit 1
    brew install tmux
    brew install reattach-to-user-namespace
  fi
fi

if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  log git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi
