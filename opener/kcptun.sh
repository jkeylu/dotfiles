#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

function install() {
  log get latest version...
  local version="$(curl -is https://github.com/xtaci/kcptun/releases/latest | sed -n 's|^Location:.*/tag/v\([a-zA-Z0-9_-]*\).*$|\1|p')"

  log "version: $version"

  local name="$(echo $os | tr '[:upper:]' '[:lower:]')"
  local filename="kcptun-${name}-386-${version}.tar.gz"
  local url="https://github.com/xtaci/kcptun/releases/download/v${version}/${filename}"
  local download_path="${TMPDIR}${filename}"

  log "download $url"
  curl -L --output "$download_path" "$url"

  tar zxvf "$download_path" -C "$bin_dir"
}

[[ 0 = $# || "-i" = $1 ]] && install && exit 0
