#!/usr/bin/env bash

source "$HOME/.dotfiles/util.sh"

show_usage() {
  cat << EOF
usage: ./.dotfiles/biu.sh [option] name

option:
  -l list all dotfiles that can be installed
  -x run script with custom args
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
    bash "$script" install
  else
    echo "script \"$script\" not found!"
  fi
}

uninstall() {
  local script="$OPENER_DIR/${1}.sh"

  if [[ -f "$script" ]]; then
    shift
    bash "$script" uninstall
  else
    echo "script \"$script\" not found!"
  fi
}

x() {
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
  -x|x)
    shift
    x "$@"
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

