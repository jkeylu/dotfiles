#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/util.sh"

show_usage() {
  cat << EOF
usage: ./biu.sh [option] name

option:
  -c run script with custom args
  -l list all dotfiles that can be installed
  -i install dotfiles
  -r restore dotfiles
  -h show this help message
EOF
}

list() {
  ls "$OPENER_DIR"
}

restore() {
  echo "Not implement" && exit 1
}

install() {
  local script="$OPENER_DIR/${1}.sh"

  if [[ -f "$script" ]]; then
    shift
    bash "$script" i "$@"
  else
    echo "script \"$script\" not found!"
  fi
}

uninstall() {
  local script="$OPENER_DIR/${1}.sh"

  if [[ -f "$script" ]]; then
    shift
    bash "$script" u "$@"
  else
    echo "script \"$script\" not found!"
  fi
}

custom() {
  local script="$OPENER_DIR/${1}.sh"

  if [[ -f "$script" ]]; then
    shift
    bash "$script" "$@"
  else
    echo "script \"$script\" not found!"
  fi
}

case "$1" in
  -h|--help|h)
    show_usage
    exit 0
    ;;
  -l|--list|l|list)
    list
    exit 0
    ;;
  -i|--install|i|install)
    shift
    install "$@"
    exit 0
    ;;
  -u|--uninstall|u|uninstall)
    shift
    uninstall "$@"
    exit 0
    ;;
  -c|c)
    shift
    custom "$@"
    exit 0
    ;;
  -r|--restore|r|restore)
    restore
    exit 0
    ;;
  *)
    echo -e "\033[31mERROR: unknown argument! \033[0m\n"
    show_usage
    exit 1
    ;;
esac

