#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

plist="$HOME/.config/hosp/hosp.plist"
launch_agents="$HOME/Library/LaunchAgents"
plist_link="$launch_agents/hosp.plist"
whitelist="$HOME/.config/hosp/whitelist.txt"
log_file="$HOME/.config/hosp/hosp.log"

install() {
  link_file .config/hosp/

  if [[ -e "$BIN_DIR/hosp" ]]; then
    log "$BIN_DIR/hosp already exists"
    exit 0
  fi

  url="https://github.com/jkeylu/hosp/releases/download/v1.1.0/hosp-macosx-amd64-v1.1.0.tar.gz"
  download_path="${TMPDIR}hosp.tar.gz"
  curl --location --output "$download_path" "$url"

  if [[ ! -f $download_path ]]; then
    log "download $url failed"
    exit 1
  fi

  [[ -d "$BIN_DIR" ]] || mkdir -p "$BIN_DIR"
  log "pouring $download_path"
  tar zxvf "$download_path" -C "$BIN_DIR" || exit 1
  chmod +x "$BIN_DIR/hosp"

  if [[ ! -e $plist ]]; then
    log "create $plist"
    sed \
      -e "9s:/Users/luhuan/.bin/hosp:$BIN_DIR/hosp:" \
      -e "11s:/Users/luhuan/.config/hosp/whitelist.txt:$whitelist:" \
      -e "19s:/Users/luhuan/.config/hosp/hosp.log:$log_file:" \
      "${plist}.sample" > "$plist"
  fi

  if [[ -e $plist_link ]]; then
    log "$plist_link is already exists"

  else
    [[ -d $launch_agents ]] || mkdir -p "$launch_agents"

    log ln -s "$plist" "$plist_link"
    ln -s "$plist" "$plist_link"
    launchctl load "$plist_link"
  fi
}

[[ 0 = $# || "-i" = $1 || "i" = $1 ]] && install && exit 0
exit 1

