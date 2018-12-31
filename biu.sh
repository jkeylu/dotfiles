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
  -s run service
  -h show this help message

examples:

./biu.sh list
./biu.sh install zsh
./biu.sh svc install kcpss server foo foo.com pass
./biu.sh run nvm update
./biu.sh run ss - install_config hello
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

service() {
  name="$2"

  case "$1" in
    install)
      shift 2
      x $name - install_service "$@"
      return
      ;;
    start)
      ensure_command pm2
      pm2 start "$CONFIG_DIR/pm2/$name.config.js"
      return
      ;;
  esac
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
  -x|x|run)
    shift
    x "$@"
    exit 0
    ;;
  -r|--restore|r|restore)
    restore
    exit 0
    ;;
  -s|--svc|--service|s|svc|service)
    shift
    service "$@"
    exit 0
    ;;
  *)
    echo -e "\033[31mERROR: unknown argument! \033[0m\n"
    show_usage
    exit 1
    ;;
esac

