#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

init_work_dir shadowsocks

LAUNCH_AGENTS="$HOME/Library/LaunchAgents"
PLIST="$I_CONFIG_DIR/ss-local.plist"
PLIST_LINK="$LAUNCH_AGENTS/ss-local.plist"
KCPTUN_PLIST="$I_CONFIG_DIR/kcptun-client.plist"
KCPTUN_PLIST_LINK="$LAUNCH_AGENTS/kcptun-client.plist"

help() {
  cat << EOF
supported commands:
  install
  install server
  install config
  uninstall
EOF
}

install() {
  link_file .config/shadowsocks/
  link_file .bin/ssc.svc
  link_file .bin/chss

  if ! command_exist kcptun-client; then
    bash "$OPENER_DIR/kcptun.sh" -i
  fi

  if [[ $OS = "Darwin" ]]; then
    [[ -d $LAUNCH_AGENTS ]] || mkdir -p "$LAUNCH_AGENTS"

    if ! command_exist ss-local; then
      command_exist brew || (log "brew is not installed" && exit 1)
      brew install shadowsocks-libev
    fi

    if [[ ! -e $KCPTUN_PLIST ]]; then
      log "create $KCPTUN_PLIST"
      cat > "$KCPTUN_PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
    <key>Label</key>
    <string>lu.jkey.kcptun-client</string>
    <key>ProgramArguments</key>
    <array>
        <string>${BIN_DIR}/ssc.svc</string>
        <string>start</string>
        <string>kcptun-client</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>${BIN_DIR}:/bin:/usr/bin:/usr/local/bin</string>
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${I_CACHE_DIR}/kcptun-client.stdout</string>
    <key>StandardErrorPath</key>
    <string>${I_CACHE_DIR}/kcptun-client.stderr</string>
    </dict>
</plist>
EOF
    fi

    if [[ ! -e $PLIST ]]; then
      log "create $PLIST"
      cat > "$PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
    <key>Label</key>
    <string>lu.jkey.ss-local</string>
    <key>ProgramArguments</key>
    <array>
        <string>${BIN_DIR}/ssc.svc</string>
        <string>start</string>
        <string>ss-local</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>${BIN_DIR}:/bin:/usr/bin:/usr/local/bin</string>
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${I_CACHE_DIR}/ss-local.stdout</string>
    <key>StandardErrorPath</key>
    <string>${I_CACHE_DIR}/ss-local.stderr</string>
    </dict>
</plist>
EOF
    fi

    if [[ -e $KCPTUN_PLIST_LINK ]]; then
      log "$KCPTUN_PLIST_LINK is already exists"
      echo -e "please run \033[0;32mlaunchctl load $KCPTUN_PLIST_LINK\033[0m"

    else
      log ln -s "$KCPTUN_PLIST" "$KCPTUN_PLIST_LINK"
      ln -s "$KCPTUN_PLIST" "$KCPTUN_PLIST_LINK"
      echo -e "please run \033[0;32mlaunchctl load $KCPTUN_PLIST_LINK\033[0m"
    fi

    if [[ -e $PLIST_LINK ]]; then
      log "$PLIST_LINK is already exists"
      echo -e "please run \033[0;32mlaunchctl load $PLIST_LINK\033[0m"

    else
      log ln -s "$PLIST" "$PLIST_LINK"
      ln -s "$PLIST" "$PLIST_LINK"
      echo -e "please run \033[0;32mlaunchctl load $PLIST_LINK\033[0m"
    fi

  fi
}

install_server() {
  link_file .config/shadowsocks/
  link_file .bin/sss.svc

  if ! command_exist kcptun-server; then
    bash "$OPENER_DIR/kcptun.sh" -i
  fi
}

install_config() {
  local config_file="$I_CONFIG_DIR/config.json"

  if [[ -n $1 ]]; then
    config_file="$I_CONFIG_DIR/${1}.config.json"
  fi

  if [[ -f $config_file ]]; then
    echo "file exists: $config_file"
    exit 0
  fi

  cat > "$config_file" << 'EOF'
{
  "server": "",
  "server_port": 34499,
  "local_port": 1080,
  "password": "",
  "timeout": 600,
  "method": "rc4-md5",
  "kcptun_server_port": 24499,
  "over_kcptun": 1,
  "log": 0
}
EOF

  echo "vim $config_file"
}

uninstall() {
  if [[ $OS = "Darwin" ]]; then
    launchctl unload "$KCPTUN_PLIST_LINK"
    launchctl unload "$PLIST_LINK"
    rm "$KCPTUN_PLIST_LINK"
    rm "$KCPTUN_PLIST"
    rm "$PLIST_LINK"
    rm "$PLIST"
  fi
}

cmd="$(join_by _ "$@")"
if [[ -n $cmd ]]; then
  "$cmd"
else
  help
fi

