#!/usr/bin/env bash

DOTFILES_DIR="$HOME/.dotfiles"

BOTTLE_DIR="$DOTFILES_DIR/bottle"
OPENER_DIR="$DOTFILES_DIR/opener"

CONFIG_DIR="$HOME/.config"
[[ -d $CONFIG_DIR ]] || mkdir "$CONFIG_DIR"

BIN_DIR="$HOME/.bin"
[[ -d $BIN_DIR ]] || mkdir "$BIN_DIR"

CACHE_DIR="$HOME/.cache"
[[ -d $CACHE_DIR ]] || mkdir "$CACHE_DIR"

BACKUP_DIR="$HOME/.dotfiles.bak"
[[ -d $BACKUP_DIR ]] || mkdir "$BACKUP_DIR"

OS=`uname`
if [[ $OS != 'Darwin' ]]; then
  if [[ -f "/etc/os-release" ]]; then
    OS_ID=`sed -n 's/^ID=\(.*\)$/\1/p' /etc/os-release`
    OS_ID_LIKE=`sed -n 's/^ID_LIKE=\(.*\)$/\1/p' /etc/os-release`

  elif [[ -f "/etc/centos-release" ]]; then
    OS_ID="centos"
    OS_ID_LIKE="redhat"
  fi
fi

log() {
  echo "  ○ $@"
}

command_exist() {
  command -v "$1" &> /dev/null
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
    rm -rf "$dest_file"
    mv "$source_file" "$bak_dir"
  fi
}

link_file() {
  local name="$1"
  if [[ "/" = ${name:0-1:1} ]]; then
    name="${name%?}"
  fi

  local bottle_file="$BOTTLE_DIR/$name"
  local link_name="$HOME/$name"

  if [[ -L $link_name ]]; then
    if [[ $(readlink "$link_name") = $bottle_file ]]; then
      log symbolic link $link_name already created
      return
    fi
  fi

  backup "$1"

  log ln -s "$bottle_file" "$link_name"
  ln -s "$bottle_file" "$link_name"
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

  log rm -rf $origin_file
  rm -rf $origin_file

  if [[ -e $bak_file ]]; then
    log restore "$origin_file"
    mv "$bak_file" "$origin_file"
  fi
}

init_work_dir() {
  MY_CONFIG_DIR="$CONFIG_DIR/$1"
  MY_CACHE_DIR="$CACHE_DIR/$1"

  [[ -d $MY_CONFIG_DIR ]] || mkdir "$MY_CONFIG_DIR"
  [[ -d $MY_CACHE_DIR ]] || mkdir "$MY_CACHE_DIR"
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

