#!/usr/bin/env bash

source "$HOME/.dotfiles/util.sh"

init_work_dir kcptun

help() {
  cat << EOF
supported commands:
  install
  install_service client #name #server_ip:#server_port:12948
  install_service server #name #server_port:#target_port
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

  local name="$(uname | tr '[:upper:]' '[:lower:]')"
  local filename="kcptun-${name}-386-${version}.tar.gz"
  local download_path="${TMPDIR}${filename}"

  gh_download $repo $tag $filename

  tar zxvf "$download_path" -C "$BIN_DIR"

  mv "${BIN_DIR}/client_${name}_386" "${BIN_DIR}/kcptun-client"
  mv "${BIN_DIR}/server_${name}_386" "${BIN_DIR}/kcptun-server"
}

server_host=""
server_port=""
target_port=""

parse_publish() {
  local publish="$1"
  local IFS=":"
  read server_host server_port target_port <<< "${publish##*-}"
  if [[ -z $target_port ]]; then
    if [[ -z $server_port ]]; then
      server_port="$server_host"
      target_port="$server_host"
      server_host=""

    else
      target_port="$server_port"

      if grep -q '^[0-9]\+$' <(echo $server_host); then
        server_port="$server_host"
        server_host=""
      fi
    fi
  fi
}

# client name server_ip:server_port:12948
# server name server_port:target_port
write_config() {
  local type="$1"
  local name="kcptun-$type-$2"
  local config_file="$MY_CONFIG_DIR/$name.json"

  parse_publish "$3"

  local listen_key=""
  local listen_value=""
  local target_key=""
  local target_value=""

  if [[ $type == "client" ]]; then
    listen_key="localaddr"
    listen_value="127.0.0.1:$target_port"
    target_key="remoteaddr"
    target_value="$server_host:$server_port"
  else
    listen_key="listen"
    listen_value=":$server_port"
    target_key="target"
    target_value="127.0.0.1:$target_port"
  fi

  cat > "$config_file" << EOF
{
  "${listen_key}": "${listen_value}",
  "${target_key}": "${target_value}",
  "crypt": "none",
  "mtu": 1200,
  "mode": "normal",
  "dscp": 46,
  "nocomp": true
}
EOF

  print_run cat "$config_file"
}

create_config() {
  local type="$1"
  local name="$2"

  local config_file="$MY_CONFIG_DIR/kcptun-$type-$name.json"
  if [[ -f $config_file ]]; then
    log "kcptun-$type-$name.json" is already created
    exit 0
  fi

  write_config "$@"

  local link_file="$MY_CONFIG_DIR/kcptun-$type.json"
  if [[ ! -L $link_file ]]; then
    print_run ln -s "$config_file" "$link_file"
  fi
}

pm2_config() {
  create_config "$@"

  local type="$1"
  local service_name="kcptun-$type"
  check_pm2_config "$service_name"

  local bin_file="$BIN_DIR/$service_name"
  local args="-c $MY_CONFIG_DIR/kcptun-$type.json"
  create_pm2_config "$service_name" "$bin_file" "$args"
}

launch_agents_config() {
  create_config "$@"

  local type="$1"
  local service_name="kcptun-$type"
  check_launch_agents_config "lu.jkey.$service_name"

  local bin_file="$BIN_DIR/$service_name"
  cat > "$LAUNCH_AGENTS/lu.jkey.$service_name.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>Label</key>
        <string>lu.jkey.${service_name}</string>

        <key>ProgramArguments</key>
        <array>
            <string>${bin_file}</string>
            <string>-c</string>
            <string>${MY_CONFIG_DIR}/kcptun-${type}.json</string>
        </array>

        <key>RunAtLoad</key>
        <true/>

        <key>KeepAlive</key>
        <true/>

        <key>StandardOutPath</key>
        <string>${LOG_DIR}/${service_name}.log</string>

        <key>StandardErrorPath</key>
        <string>${LOG_DIR}/${service_name}.log</string>
    </dict>
</plist>
EOF
}

install_service() {
  local type="$1"
  local name="$2"

  if [[ $type != "server" && $type != "client" ]]; then
    log type only support "server" or "client"
    exit 1
  fi

  if ! grep -i -q '^[a-z][a-z0-9]*$' <(echo "$name"); then
    log config name "$name" is not valid
    exit 1
  fi

  if is_osx; then
    launch_agents_config "$@"

  else
    pm2_config "$@"
  fi
}

run_cmd "$@"

