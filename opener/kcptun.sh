#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

help() {
  cat << EOF
supported commands:
  install
EOF
}

install() {
  if [[ -e "$BIN_DIR/kcptun-client" ]]; then
    log "kcptun already installed"
    exit 0
  fi

  log get latest version...
  local version="$(curl -is https://github.com/xtaci/kcptun/releases/latest | sed -n 's|^Location:.*/tag/v\([a-zA-Z0-9_-]*\).*$|\1|p')"

  log "version: $version"

  local name="$(echo $OS | tr '[:upper:]' '[:lower:]')"
  local filename="kcptun-${name}-386-${version}.tar.gz"
  local url="https://github.com/xtaci/kcptun/releases/download/v${version}/${filename}"
  local download_path="${TMPDIR}${filename}"

  log "download $url"
  curl -L --output "$download_path" "$url"

  tar zxvf "$download_path" -C "$BIN_DIR"

  mv "${BIN_DIR}/client_${name}_386" "${BIN_DIR}/kcptun-client"
  mv "${BIN_DIR}/server_${name}_386" "${BIN_DIR}/kcptun-server"
}

cmd="$(join_by _ "$@")"
if [[ -n $cmd ]]; then
  "$cmd"
else
  help
fi

