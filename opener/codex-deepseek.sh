#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPT_DIR/../util.sh"

install() {
  local codex_dir="$HOME/.codex"
  local chatgpt_codex_dir="$HOME/.codex.chatgpt"

  confirm "If the ChatGPT app is running, close it before continuing." Y yes

  if [[ -e "$chatgpt_codex_dir" || -L "$chatgpt_codex_dir" ]]; then
    log "skipping the move"
  elif [[ -e "$codex_dir" || -L "$codex_dir" ]]; then
    print_run mv -- "$codex_dir" "$chatgpt_codex_dir"
    print_run cp -a -- "$chatgpt_codex_dir" "$codex_dir"
  else
    log "$codex_dir does not exist; skipping the move"
  fi

  install_direct
}

install_direct() {
  if is_win; then
    ensure_command powershell.exe
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \
      '[Text.Encoding]::UTF8.GetString((iwr -Uri "https://cdn.deepseek.com/api-docs/codex-deepseek-setup.ps1" -UseBasicParsing).RawContentStream.ToArray()) | iex'
  else
    ensure_command curl
    bash <(curl -fsSL https://cdn.deepseek.com/api-docs/codex-deepseek-setup.sh)
  fi
}

run_cmd "$@"
