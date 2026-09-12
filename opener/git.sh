#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPT_DIR/../util.sh"

install() {
  link_file .gitconfig

  check_command git

  if is_osx; then
    print_run xcode-select --install

  elif is_debian; then
    print_run sudo apt-get install git

  elif is_arch; then
    print_run sudo pacman -S git

    elif is_centos; then
      print_run sudo yum install git

    else
      error "git is required, please install git first"
      return 1
    fi
}

run_cmd "$@"
