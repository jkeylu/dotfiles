#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPT_DIR/../util.sh"

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

