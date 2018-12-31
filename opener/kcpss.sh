#!/usr/bin/env bash

source "$HOME/.dotfiles/util.sh"

help() {
  cat << EOF
supported commands:
  install_service client #name #server #password
  install_service server #name #server #password
EOF
}

install_service() {
  local type="$1"
  local name="$2"
  local server="$3"
  local password="$4"

  if [[ $type != "server" && $type != "client" ]]; then
    log type only support "server" or "client"
    exit 1
  fi

  if ! grep -i -q '^[a-z][a-z0-9]*$' <(echo "$name"); then
    log config name "$name" is not valid
    exit 1
  fi

  local ss_script="$OPENER_DIR/ss.sh"
  local kcptun_script="$OPENER_DIR/kcptun.sh"

  if [[ $type = "client" ]]; then
    bash "$kcptun_script" - "install_service" "client" "$name" "$server:24499:12948"
    bash "$ss_script" - "install_service" "local" "$name" "$server" "34499" "$password"
    bash "$ss_script" - "create_config" "local" "$name.kcpten" "127.0.0.1" "12948" "$password"
  else
    bash "$kcptun_script" - "install_service" "server" "$name" "$server:24499:34499"
    bash "$ss_script" - "install_service" "server" "$name" "0.0.0.0" "34499" "$password"
  fi
}

run_cmd "$@"

