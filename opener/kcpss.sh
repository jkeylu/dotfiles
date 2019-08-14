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
    bash "$kcptun_script" - "install_service" "client" "$name" "$server:40255:40155"
    bash "$ss_script" - "install_service" "local" "$name" "$server" "40055" "$password"
    bash "$ss_script" - "create_config" "local" "$name.kcptun" "127.0.0.1" "40155" "$password"
  else
    bash "$kcptun_script" - "install_service" "server" "$name" "$server:40255:40055"
    bash "$ss_script" - "install_service" "server" "$name" "0.0.0.0" "40055" "$password"
  fi
}

run_cmd "$@"

