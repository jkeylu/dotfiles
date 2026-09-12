#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPT_DIR/../util.sh"

install() {
  if is_win; then
    link_file .bashrc_win .bashrc
    link_file .bash_profile
  else
    link_file .bashrc
    link_file .bash_profile
  fi
}

run_cmd "$@"

