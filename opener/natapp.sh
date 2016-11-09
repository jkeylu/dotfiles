#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

function install() {
  if [[ -e "$bin_dir/ngrok" ]]; then
    log "$bin_dir/ngrok already exists"
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
  unzip "$download_path" -d "$bin_dir"
  chmod +x "$bin_dir/ngrok"
}

[[ 0 = $# || "-i" = $1 ]] && install && exit 0

