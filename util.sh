#!/usr/bin/env bash

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BOTTLE_DIR="$__dir/bottle"
OPENER_DIR="$__dir/opener"

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
  OS_ID=`sed -n 's/^ID=\(.*\)$/\1/p' /etc/os-release`
  OS_ID_LIKE=`sed -n 's/^ID_LIKE=\(.*\)$/\1/p' /etc/os-release`
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

