#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

plist="$HOME/.config/hosp/hosp.plist"
launch_agents="$HOME/Library/LaunchAgents"
plist_link="$launch_agents/hosp.plist"
whitelist="$HOME/.config/hosp/whitelist.txt"
log_file="$HOME/.config/hosp/hosp.log"
bin_dir="$HOME/.bin"

link_file .config/hosp/

if [[ -e "$bin_dir/hosp" ]]; then
  log $bin_dir/hosp already exists
  exit 0
fi

url="https://github.com/jkeylu/hosp/releases/download/v1.1.0/hosp-macosx-amd64-v1.1.0.tar.gz"
download_path="${TMPDIR}hosp.tar.gz"
curl --location --output "$download_path" "$url"

if [[ ! -f $download_path ]]; then
  log download $url failed
  exit 1
fi

[[ -d "$bin_dir" ]] || mkdir -p "$bin_dir"
log pouring $download_path
tar zxvf "$download_path" -C "$bin_dir" || exit 1
chmod +x "$bin_dir/hosp"

if [[ ! -e $plist ]]; then
  log create "$plist"
  sed \
    -e "9s:/Users/luhuan/.bin/hosp:$bin_dir/hosp:" \
    -e "11s:/Users/luhuan/.config/hosp/whitelist.txt:$whitelist:" \
    -e "19s:/Users/luhuan/.config/hosp/hosp.log:$log_file:" \
    "${plist}.sample" > "$plist"
fi

if [[ -e $plist_link ]]; then
  log "$plist_link" is already exists

else
  [[ -d $launch_agents ]] || mkdir -p "$launch_agents"

  log ln -s "$plist" "$plist_link"
  ln -s "$plist" "$plist_link"
  launchctl load "$plist_link"
fi

