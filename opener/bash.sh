#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

install() {
  link_file .bashrc
  link_file .bash_profile
  link_file .shell_alias
  link_file .shell_function
}

[[ 0 = $# || "-i" = $1 || "i" = $1 ]] && install && exit 0
exit 1

