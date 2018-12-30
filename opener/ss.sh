#!/usr/bin/env bash

source "$HOME/.dotfiles/util.sh"

init_work_dir shadowsocks

help() {
  cat << EOF
supported commands:
  install
  install_service local #name
  install_service server #name
EOF
}

install() {
  check_command ss-local

  if is_osx; then
    ensure_command brew
    brew install shadowsocks-libev
  elif is_debian; then
    sudo apt-get install --no-install-recommends gettext build-essential autoconf libtool libpcre3-dev asciidoc xmlto libev-dev libc-ares-dev automake libmbedtls-dev libsodium-dev
  else
    log system not supported
  fi
}

write_config() {
  local type="$1"
  local name="ss-$type-$2"
  local config_file="$MY_CONFIG_DIR/$name.json"

  cat > "$config_file" << 'EOF'
{
  "server": "_SERVER_IP_",
  "server_port": 14499,
  "local_port": 1080,
  "password": "_PASSWORD_",
  "timeout": 600,
  "method": "rc4-md5",
  "log": 0
}
EOF

  if command_exist vim; then
    print_run vim "$config_file"
  else
    echo "vim $config_file"
  fi
}

create_config() {
  local type="$1"
  local name="$2"

  local config_file="$MY_CONFIG_DIR/ss-$type-$name.json"
  if [[ -f $config_file ]]; then
    log "ss-$type-$name.json" is already created
    exit 0
  fi

  write_config "$@"

  local link_file="$MY_CONFIG_DIR/ss-$type.json"
  if [[ ! -L $link_file ]]; then
    print_run ln -s "$config_file" "$link_file"
  fi
}

pm2_config() {
  local type="$1"
  local name="$2"

  create_config "$@"

  local service_name="ss-$type"
  check_pm2_config "$service_name"

  local bin_file="$BIN_DIR/$service_name"
  local args="-c $MY_CONFIG_DIR/ss-$type.json"
  create_pm2_config "$service_name" "$bin_file" "$args"
}

launch_agents_config() {
  create_config "$@"

  local type="$1"
  local service_name="ss-$type"
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
            <string>${MY_CONFIG_DIR}/${service_name}.json</string>
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

  if [[ $type != "server" && $type != "local" ]]; then
    log type only support "server" or "local"
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
