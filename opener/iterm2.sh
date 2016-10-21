#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

function install() {
  link_file .config/iTerm2/
}

[[ 0 = $# || "-i" = $1 ]] && install && exit 0

