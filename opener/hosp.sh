#!/usr/bin/env bash

source "$HOME/.dotfiles/util.sh"

init_work_dir hosp

help() {
  cat << EOF
supported commands:
  install
EOF
}

install() {
  local launch_agents="$HOME/Library/LaunchAgents"
  local plist="$MY_CONFIG_DIR/hosp.plist"
  local plist_link="$launch_agents/hosp.plist"
  local whitelist="$MY_CONFIG_DIR/whitelist.txt"
  local url="https://github.com/jkeylu/hosp/releases/download/v1.1.0/hosp-macosx-amd64-v1.1.0.tar.gz"
  local download_path="${TMPDIR}hosp.tar.gz"

  if [[ -e "$BIN_DIR/hosp" ]]; then
    log "$BIN_DIR/hosp already exists"

  else
    curl --location --output "$download_path" "$url"

    if [[ ! -f $download_path ]]; then
      log "download $url failed"
      exit 1
    fi

    log "pouring $download_path"
    tar zxvf "$download_path" -C "$BIN_DIR" || exit 1
    chmod +x "$BIN_DIR/hosp"
  fi

  if [[ ! -e $plist ]]; then
    log "create $plist"
    cat > "$plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>lu.jkey.hosp</string>
    <key>ProgramArguments</key>
    <array>
      <string>${BIN_DIR}/hosp</string>
      <string>-w</string>
      <string>${whitelist}</string>
      <string>-verbose</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${MY_CACHE_DIR}/hosp.stdout</string>
    <key>StandardErrorPath</key>
    <string>${MY_CACHE_DIR}/hosp.stderr</string>
  </dict>
</plist>
EOF
  fi

  if [[ -e $plist_link ]]; then
    log "$plist_link is already exists"
    echo -e " please run \033[0;32mlaunchctl load $plist_link\033[0m"

  else
    [[ -d $launch_agents ]] || mkdir -p "$launch_agents"

    log ln -s "$plist" "$plist_link"
    ln -s "$plist" "$plist_link"
    echo -e " please run \033[0;32mlaunchctl load $plist_link\033[0m"
  fi
}

run_cmd "$@"

