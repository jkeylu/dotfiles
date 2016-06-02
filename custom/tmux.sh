#!/usr/bin/env bash

[[ __util__ = 1 ]] || [[ -e util.sh ]] && source util.sh || source ../util.sh

if [[ $(uname) = "Darwin" ]]; then
  if ! command -v tmux > /dev/null 2>&1; then
    command -v brew > /dev/null 2>&1 || log "brew is not installed" && exit 1
    brew install tmux
  fi

  if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    log git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  fi
fi
