#!/usr/bin/env bash

source "$HOME/.dotfiles/util.sh"

help() {
  cat << EOF
supported commands:
  install
EOF
}

install() {
  if [[ -f "$BIN_DIR/.kcptun.version" ]]; then
    local current_version="$(cat "$BIN_DIR/.kcptun.version")"
    log "current version: $current_version"
  fi

  log get latest version...
  local version="$(curl -is https://github.com/xtaci/kcptun/releases/latest | sed -n 's|^Location:.*/tag/v\([a-zA-Z0-9_-]*\).*$|\1|p')"

  log "remote version: $version"

  if [[ $version == $current_version ]]; then
    log "$version is latest version"
    exit 0
  fi

  local name="$(echo $OS | tr '[:upper:]' '[:lower:]')"
  local filename="kcptun-${name}-386-${version}.tar.gz"
  local url="https://github.com/xtaci/kcptun/releases/download/v${version}/${filename}"
  local download_path="${TMPDIR}${filename}"

  log "download $url"
  curl -L --output "$download_path" "$url"

  tar zxvf "$download_path" -C "$BIN_DIR"

  mv "${BIN_DIR}/client_${name}_386" "${BIN_DIR}/kcptun-client"
  mv "${BIN_DIR}/server_${name}_386" "${BIN_DIR}/kcptun-server"
  echo "$version" > "$BIN_DIR/.kcptun.version"
}

run_cmd "$@"

