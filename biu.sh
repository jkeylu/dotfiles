#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/util.sh"

function show_usage() {
  cat << EOF
usage: ./biu.sh [option] name

option:
  -l list all dotfiles that can be installed
  -i install dotfiles
  -r restore dotfiles
  -h show this help message
EOF
}

function list() {
  ls "$opener_dir"
}

function restore() {
  echo "Not implement" && exit 1
}

function install() {
  local script="$opener_dir/${1}.sh"

  if [[ -f "$script" ]]; then
    bash "$script" -i
  else
    echo "script \"$script\" not found!"
  fi
}

[[ 0 = $# ]] && show_usage && exit 1

while :; do
  [[ -z $1 ]] && break;

  case "$1" in
    -h|--help)
      show_usage
      exit 0
      ;;
    -l|--list)
      list
      exit 0
      ;;
    -i|--install)
      install "$2"
      exit 0
      ;;
    -r|--restore)
      restore
      exit 0
      ;;
    *)
      echo -e "\033[31mERROR: unknown argument! \033[0m\n"
      show_usage
      exit 1
      ;;
  esac
done
