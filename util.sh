#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

BOTTLE_DIR="$DOTFILES_DIR/bottle"
OPENER_DIR="$DOTFILES_DIR/opener"

CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.dotfiles.bak"

is_win() {
  [[ "$(uname)" == "MINGW64_NT"* ]]
}

is_osx() {
  [[ "$(uname)" == "Darwin" ]]
}

is_debian() {
  [[ -f "/etc/os-release" ]] && grep -q "debian" /etc/os-release
}

is_ubuntu() {
  [[ -f "/etc/os-release" ]] && grep -q "ubuntu" /etc/os-release
}

is_arch() {
  [[ -f "/etc/os-release" ]] && grep -q "arch" /etc/os-release
}

is_centos() {
  [[ -f "/etc/centos-release" ]]
}

log() {
  printf '  ○ %s\n' "$*"
}

error() {
  printf 'Error: %s\n' "$*" >&2
}

print_run() {
  log "$@"
  "$@"
}

command_exist() {
  command -v "$1" &> /dev/null
}

ensure_command() {
  if ! command_exist "$1"; then
    error "command '$1' is not installed"
    exit 1
  fi
}

check_command() {
  if command_exist "$1"; then
    log "$1 is already installed"
    exit 0
  fi
}

backup() {
  local name="$1"
  local source_file="$HOME/$name"
  local dest_file="$BACKUP_DIR/$name"
  local bak_dir="$BACKUP_DIR"

  if [[ "/" = ${name:0-1:1} ]]; then
    source_file="${source_file%?}"
    dest_file="${dest_file%?}"
    bak_dir="$bak_dir/${name%?}"
    bak_dir="${bak_dir%/*}"
  fi

  if [[ -e $source_file || -L $source_file ]]; then
    [[ -d $bak_dir ]] || mkdir -p "$bak_dir"

    log "backup $source_file"
    if [[ -e $dest_file || -L $dest_file ]]; then
      mv "$dest_file" "${dest_file}.$(date +%Y%m%d%H%M%S)"
    fi
    mv "$source_file" "$bak_dir"
  fi
}

is_link_file() {
  local name="$1"
  if [[ "/" = ${name:0-1:1} ]]; then
    name="${name%?}"
  fi

  local bottle_file="$BOTTLE_DIR/$name"
  local link_name="$HOME/$name"

  if [[ -L $link_name ]]; then
    if [[ $(readlink "$link_name") = "$bottle_file" ]]; then
      return 0
    fi
  fi

  return 1
}

create_symbolic_link() {
  local target="$1"
  local link_name="$2"

  if is_win; then
    if [[ -d "$target" ]]; then
      # Windows: use mklink /J for directories (junctions don't require admin privileges)
      # MSYS_NO_PATHCONV prevents Git Bash from converting /c to a Windows path
      local win_link
      local win_target
      win_link="$(cygpath -w "$link_name")"
      win_target="$(cygpath -w "$target")"
      log "mklink /J $win_link $win_target"
      MSYS_NO_PATHCONV=1 cmd.exe /c mklink /J "$win_link" "$win_target"
      return
    fi

    printf '\n'
    printf '%s\n' "Note: If you are using Windows, please make sure Developer Mode is enabled to allow creating symbolic links without admin privileges."
    printf '%s\n' "      Alternatively, you can manually create the symbolic link with the following command:"
    printf '%s\n' "      mklink $(cygpath -w "$link_name") $(cygpath -w "$target")"
    printf '\n'
  fi

  print_run ln -s "$target" "$link_name"
}

link_file() {
  local bottle_file_name="$1"
  # remove trailing slash if exists
  if [[ "/" = ${bottle_file_name:0-1:1} ]]; then
    bottle_file_name="${bottle_file_name%?}"
  fi

  local link_file_name="${2:-$bottle_file_name}"

  local bottle_file="$BOTTLE_DIR/$bottle_file_name"
  local link_name="$HOME/$link_file_name"

  if [[ ! -d ${link_name%/*} ]]; then
    mkdir -p "${link_name%/*}"
  fi

  if [[ -L $link_name ]]; then
    if [[ $(readlink "$link_name") = "$bottle_file" ]]; then
      log "symbolic link $link_name already created"
      return
    fi
  fi

  backup "${2:-$1}"

  create_symbolic_link "$bottle_file" "$link_name"
}

init_work_dir() {
  MY_CONFIG_DIR="$CONFIG_DIR/$1"
  [[ -d $MY_CONFIG_DIR ]] || mkdir -p "$MY_CONFIG_DIR"
}

gh_latest_tag() {
  local repo="$1"
  local tag
  tag="$(curl -is "https://github.com/${repo}/releases/latest" | sed -n 's|^Location:.*/tag/\(.*\)$|\1|p' | tr -d '\r\n')"
  if [[ -z $tag ]]; then
    tag="$(curl -s "https://github.com/${repo}/releases" | grep -o -m 1 'tag/[^"]\+' | sed -n 's|tag/\(.*\)$|\1|p')"
  fi
  printf '%s\n' "$tag"
}

gh_download() {
  local repo="$1"
  local version="$2"
  local filename="$3"

  local url="https://github.com/${repo}/releases/download/${version}/${filename}"
  local temp_dir="${TMPDIR:-/tmp}"
  local download_path="${temp_dir%/}/${filename}"

  log "downloading $url"
  curl -L --output "$download_path" "$url"
}

_biu_is_base_function() {
  local candidate="$1"
  local base_function

  while IFS= read -r base_function; do
    if [[ "$candidate" == "$base_function" ]]; then
      return 0
    fi
  done <<< "$_BIU_BASE_FUNCTIONS"

  return 1
}

_biu_supported_actions() {
  local action

  for action in $(compgen -A function); do
    [[ "$action" == _* ]] && continue
    _biu_is_base_function "$action" && continue
    printf '%s\n' "$action"
  done
}

_biu_supported_actions_inline() {
  local action
  local actions=""

  while IFS= read -r action; do
    [[ -n "$action" ]] || continue
    actions="${actions:+$actions }$action"
  done < <(_biu_supported_actions)

  printf '%s\n' "$actions"
}

_biu_show_help() {
  local action

  printf 'supported actions:\n'
  while IFS= read -r action; do
    [[ -n "$action" ]] || continue
    printf '  %s\n' "$action"
  done < <(_biu_supported_actions)
}

_biu_is_supported_action() {
  local candidate="$1"
  local action

  while IFS= read -r action; do
    if [[ "$candidate" == "$action" ]]; then
      return 0
    fi
  done < <(_biu_supported_actions)

  return 1
}

run_cmd() {
  local command_name="${1:-help}"
  if (($# > 0)); then
    shift
  fi

  if [[ "$command_name" == help ]]; then
    if (($# != 0)); then
      error "help does not accept arguments"
      return 2
    fi
    _biu_show_help
    return 0
  fi

  if ! _biu_is_supported_action "$command_name"; then
    error "unsupported action '$command_name'; supported actions: $(_biu_supported_actions_inline)"
    return 2
  fi

  "$command_name" "$@"
}

extract_zip() {
  local filename="$1"
  local exdir="$2"

  if command_exist unzip; then
    unzip -o "$filename" -d "$exdir"
  elif command_exist python; then
    python -m zipfile -e "$filename" "$exdir"
  elif command_exist python3; then
    python3 -m zipfile -e "$filename" "$exdir"
  else
    error "unzip, python, or python3 is required to extract zip files"
    exit 1
  fi
}

_BIU_BASE_FUNCTIONS="$(compgen -A function)"
readonly _BIU_BASE_FUNCTIONS
