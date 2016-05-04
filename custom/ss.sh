#!/usr/bin/env bash

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
function log() {
  echo "  ○ $@"
}

plist="$HOME/.config/shadowsocks/shadowsocks-libev.plist"
launch_agents="$HOME/Library/LaunchAgents"
plist_link="$launch_agents/shadowsocks-libev.plist"
config="$HOME/.config/shadowsocks/config.json"
log="$HOME/.config/shadowsocks/ss.log"

if [[ $(uname) = "Darwin" ]]; then
  if ! command -v ss-local >/dev/null 2>&1; then
    if ! command -v brew >/dev/null 2>&1; then
      log "brew is not installed"
      exit 1
    fi

    brew install shadowsocks-libev
  fi

  if [[ ! -d "$HOME/.config/shadowsocks" ]]; then
    log "$HOME/.config/shadowsocks" not found
    log please run ./biu.sh -i
  fi

  if [[ ! -e $plist ]]; then
    log create "$plist"
    sed \
      -e "11s:/Users/luhuan/.config/shadowsocks/config.json:$config:" \
      -e "19s:/Users/luhuan/.config/shadowsocks/ss.log:$log:" \
      "${plist}.sample" > "$plist"
  fi

  if [[ -e $plist_link ]]; then
    log "$plist_link" is already exists

  else
    [[ -d $launch_agents ]] || mkdir -p "$launch_agents"

    log ln -s "$plist" "$plist_link"
    ln -s "$plist" "$plist_link"
  fi
fi
