#!/usr/bin/env bash

source "$HOME/.dotfiles/util.sh"

init_work_dir kcptun

help() {
  cat << EOF
supported commands:
  install
  pm2config
EOF
}

install() {
  if [[ -x "$BIN_DIR/kcptun-client" ]]; then
    local current_version="$($BIN_DIR/kcptun-client --version | grep -o '[0-9]\{8\}')"
    log "current version: $current_version"
  fi

  local repo="xtaci/kcptun"

  log fetching latest version...
  local tag=`gh_latest_tag $repo`
  local version="${tag#v}"

  log "remote version: $version"

  if [[ $version == $current_version ]]; then
    log "$version is latest version"
    exit 0
  fi

  local name="$(echo $OS | tr '[:upper:]' '[:lower:]')"
  local filename="kcptun-${name}-386-${version}.tar.gz"
  local download_path="${TMPDIR}${filename}"

  gh_download $repo $tag $filename

  tar zxvf "$download_path" -C "$BIN_DIR"

  mv "${BIN_DIR}/client_${name}_386" "${BIN_DIR}/kcptun-client"
  mv "${BIN_DIR}/server_${name}_386" "${BIN_DIR}/kcptun-server"
}

pm2config() {
  local type="$1"
  local name="$2"
  local bin_file="$BIN_DIR/kcptun-$type"
  local file_path="$MY_CONFIG_DIR/$type-$name.config.js"
  local args=""

  if [[ $# -eq 0 ]]; then
    ls -l "$MY_CONFIG_DIR" | grep --color '[^ ]\+.config.js'
    exit 0
  fi

  if [[ $type != "server" && $type != "client" ]]; then
    log type only support server or client
    exit 1
  fi

  if [[ $type == "server" ]]; then
    args="-l :server_port -t 127.0.0.1:target_port --crypt none --mtu 1200 --mode normal --dscp 46 --nocomp"
  else
    args="-l 127.0.0.1:target_port -r server_host:server_port --crypt none --mtu 1200 --mode normal --dscp 46 --nocomp"
  fi

  cat > "$file_path" << EOF
module.exports = {
  apps: [
    {
      name: 'kcptun-$type-$name',
      script: '$bin_file',
      args: '$args'
      log_date_format: 'YYMMDD HH:mm:ss Z'
    }
  ]
}
EOF

  echo "RUN pm2 start $file_path"
}

run_cmd "$@"

