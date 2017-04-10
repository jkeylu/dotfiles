#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

help() {
  cat << EOF
supported commands:
  install
EOF
}

install() {
  if [[ -e "$BIN_DIR/ngrok" ]]; then
    log "$BIN_DIR/ngrok already exists"
    exit 0
  fi

  html="$(curl http://natapp.cn)"
  url="$(echo "$html" | grep -o 'http://[^\"]*/ngrok_mac\.zip')"

  if [[ -z $url ]]; then
    log "$html"
    log "can not match ngrock download url"
    exit 1
  fi

  log "download $url"
  download_path="${TMPDIR}ngrok_mac.zip"
  curl --output "$download_path" "$url"

  if [[ ! -f $download_path ]]; then
    log "download $url failed"
    exit 1
  fi

  log "pouring $download_path"
  unzip "$download_path" -d "$BIN_DIR"
  chmod +x "$BIN_DIR/ngrok"
}

cmd="$(join_by _ "$@")"
if [[ -n $cmd ]]; then
  "$cmd"
else
  help
fi

