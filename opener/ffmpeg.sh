#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPT_DIR/../util.sh"

install() (
  if ! is_win && ! is_osx; then
    error "ffmpeg installation is only supported on Windows and macOS"
    return 1
  fi

  local bin_dir="$HOME/.local/bin"
  local temp_dir tool url
  temp_dir="$(mktemp -d)"
  trap 'rm -rf -- "$temp_dir"' EXIT
  mkdir -p "$bin_dir"

  if is_win; then
    curl -fL "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip" -o "$temp_dir/ffmpeg.zip"
    extract_zip "$temp_dir/ffmpeg.zip" "$temp_dir"
    cp -f "$temp_dir"/ffmpeg*/bin/*.exe "$bin_dir/"
  else
    for tool in ffmpeg ffprobe; do
      url="https://evermeet.cx/ffmpeg/getrelease/$tool/zip"
      if [[ "$(uname -m)" == arm64 ]]; then
        url="https://ffmpeg.martin-riedl.de/redirect/latest/macos/arm64/release/$tool.zip"
      fi
      curl -fL "$url" -o "$temp_dir/$tool.zip"
      extract_zip "$temp_dir/$tool.zip" "$temp_dir"
      cp -f "$temp_dir/$tool" "$bin_dir/"
      chmod +x "$bin_dir/$tool"
    done
  fi

  log "ffmpeg installed to $bin_dir"
)

run_cmd "$@"
