#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPT_DIR/../util.sh"

install() {
  if [[ -d "$HOME/.local/miniforge3" ]]; then
    log "miniforge already installed"
    exit 0
  fi

  curl -L -o "$HOME/Miniforge3-$(uname)-$(uname -m).sh" "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
  bash "$HOME/Miniforge3-$(uname)-$(uname -m).sh" -b -p "$HOME/.local/miniforge3"
}

run_cmd "$@"

