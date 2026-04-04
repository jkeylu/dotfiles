#!/usr/bin/env bash

DOTFILES_DIR="$HOME/.dotfiles"

BOTTLE_DIR="$DOTFILES_DIR/bottle"
OPENER_DIR="$DOTFILES_DIR/opener"

CONFIG_DIR="$HOME/.config"
[[ -d $CONFIG_DIR ]] || mkdir "$CONFIG_DIR"

BIN_DIR="$HOME/.bin"
[[ -d $BIN_DIR ]] || mkdir "$BIN_DIR"

LOG_DIR="$HOME/.log"
[[ -d $LOG_DIR ]] || mkdir "$LOG_DIR"

BACKUP_DIR="$HOME/.dotfiles.bak"
[[ -d $BACKUP_DIR ]] || mkdir "$BACKUP_DIR"

LAUNCH_AGENTS="$HOME/Library/LaunchAgents"

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
  echo "  ○ $@"
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
    log command "$1" is not installed
    exit 1
  fi
}

check_command() {
  if command_exist "$1"; then
    log "$1" is already installed
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

    log backup $source_file
    if [[ -e $dest_file ]]; then
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
    if [[ $(readlink "$link_name") = $bottle_file ]]; then
      return 0 # true
    fi
  fi

  return 1 # false
}

create_symbolic_link() {
  local target="$1"
  local link_name="$2"

  if is_win; then
    echo ""
    echo "Note: If you are using Windows, please make sure Developer Mode is enabled to allow creating symbolic links without admin privileges."
    echo "      Alternatively, you can manually create the symbolic link with the following command:"
    echo "      mklink $(cygpath -w "$link_name") $([[ -d "$target" ]] && echo "/D ")$(cygpath -w "$target")"
    echo ""
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
    if [[ $(readlink "$link_name") = $bottle_file ]]; then
      log symbolic link $link_name already created
      return
    fi
  fi

  backup "${2:-$1}"

  create_symbolic_link "$bottle_file" "$link_name"
}

restore_file() {
  local name="$1"
  if [[ "/" = ${name:0-1:1} ]]; then
    name="${name%?}"
  fi

  local bak_file="$BACKUP_DIR/$name"
  local origin_file="$HOME/$name"
  local bottle_file="$BOTTLE_DIR/$name"

  if [[ ! -L $origin_file ]]; then
    return
  fi

  if [[ $(readlink "$origin_file") != $bottle_file ]]; then
    return
  fi

  print_run rm -rf $origin_file

  if [[ -e $bak_file ]]; then
    log restore "$origin_file"
    mv "$bak_file" "$origin_file"
  fi
}

init_work_dir() {
  MY_CONFIG_DIR="$CONFIG_DIR/$1"
  [[ -d $MY_CONFIG_DIR ]] || mkdir "$MY_CONFIG_DIR"
}

# http://stackoverflow.com/questions/1527049/join-elements-of-an-array
join_by() {
  local IFS="$1"
  shift
  echo "$*"
}

gh_latest_tag() {
  local repo="$1"
  local tag="$(curl -is https://github.com/${repo}/releases/latest | sed -n 's|^Location:.*/tag/\(.*\)$|\1|p' | tr -d '\r\n')"
  if [[ -z $tag ]]; then
    tag="$(curl -s https://github.com/${repo}/releases | grep -o -m 1 'tag/[^"]\+' | sed -n 's|tag/\(.*\)$|\1|p')"
  fi
  echo "$tag"
}

gh_download() {
  local repo="$1"
  local version="$2"
  local filename="$3"

  local url="https://github.com/${repo}/releases/download/${version}/${filename}"
  local download_path="${TMPDIR}${filename}"

  log downloading $url
  curl -L --output "$download_path" "$url"
}

run_cmd() {
  local cmd="$(join_by _ "$@")"

  if [[ $1 = "-" ]]; then
    cmd="$2"
    shift 2
    "$cmd" "$@"

  elif [[ -n $cmd ]]; then
    "$cmd"

  else
    help
  fi
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
    log not found unzip command
    exit 1
  fi
}
