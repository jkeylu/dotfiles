#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

function install() {
  if [[ -e "$bin_dir/kcptun_client" ]]; then
    log "kcptun already installed"
    exit 0
  fi

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

  mv "${bin_dir}/client_${name}_386" "${bin_dir}/kcptun_client"
  mv "${bin_dir}/server_${name}_386" "${bin_dir}/kcptun_server"
}

[[ 0 = $# || "-i" = $1 ]] && install && exit 0
