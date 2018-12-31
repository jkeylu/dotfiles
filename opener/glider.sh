#!/usr/bin/env bash

source "$HOME/.dotfiles/util.sh"

init_work_dir glider

help() {
  cat << EOF
supported commands:
  install
  install_service
EOF
}

install() {
  if [[ -x "$BIN_DIR/glider" ]]; then
    local current_version="$($BIN_DIR/glider --version)"
  fi

  local repo="nadoo/glider"

  log fetching latest version...
  local version=`gh_latest_tag $repo`

  log remote version: $version

  local name="linux"
  if is_osx; then
    name="macosx"
  fi
  if uname -m | grep -q '64'; then
    name="${name}-amd64"
  else
    name="${name}-386"
  fi

  local filename="glider-$version-$name.zip"
  gh_download $repo $version $filename

  tmp_exdir="${TMPDIR}glider"
  extract_zip "${TMPDIR}${filename}" "$tmp_exdir/"
  mv "$tmp_exdir/glider" "$BIN_DIR"
  chmod +x "$BIN_DIR/glider"
}

pm2_config() {
  check_pm2_config "glider"

  create_pm2_config "glider" "$BIN_DIR/glider" "-config $MY_CONFIG_DIR/glider.conf"
}

launch_agents_config() {
  local service_name="glider"
  check_launch_agents_config "lu.jkey.$service_name"

  cat > "$LAUNCH_AGENTS/lu.jkey.$service_name.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>Label</key>
        <string>lu.jkey.${service_name}</string>

        <key>ProgramArguments</key>
        <array>
            <string>${BIN_DIR}/${service_name}</string>
            <string>-config</string>
            <string>${MY_CONFIG_DIR}/${service_name}.conf</string>
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
  link_file .config/glider/glider.conf

  if is_osx; then
    launch_agents_config

  else
    pm2_config
  fi
}

run_cmd "$@"
