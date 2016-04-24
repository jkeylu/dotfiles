#!/usr/bin/env bash

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__root="$(cd "$(dirname "${__dir}")" && pwd)"

function link_dot_file() {
  local name=$1

  if [ -L "$HOME/$name" ]; then
  fi

  if [ -d "$HOME/$name" ]; then
  fi
}

function restore_dot_file() {
}
