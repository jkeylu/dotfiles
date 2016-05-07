#!/usr/bin/env bash

[[ -e util.sh ]] && source util.sh || source ../util.sh

if [[ -e "$HOME/.bin/ngrok" ]]; then
  log $HOME/.bin/ngrok already exists
  exit 0
fi

html="$(curl http://natapp.cn)"
url="$(echo "$html" | grep -o 'http://[^\"]*/ngrok_mac\.zip')"

if [[ -z $url ]]; then
  log $html
  log can not match ngrock download url
  exit 1
fi

log download $url
download_path="${TMPDIR}ngrok_mac.zip"
curl --output "$download_path" "$url"

if [[ ! -f $download_path ]]; then
  log download $url failed
  exit 1
fi

[[ -d "$HOME/.bin" ]] || mkdir -p "$HOME/.bin"
log pouring $download_path
unzip $download_path -d "$HOME/.bin"
chmod +x "$HOME/.bin/ngrok"
