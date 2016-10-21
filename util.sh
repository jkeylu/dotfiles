#!/usr/bin/env bash

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bottle_dir="$__dir/bottle"
opener_dir="$__dir/opener"

config_dir="$HOME/.config"
[[ -d $config_dir ]] || mkdir "$config_dir"

cache_dir="$HOME/.cache"
[[ -d $cache_dir ]] || mkdir "$cache_dir"

backup_dir="$HOME/.dotfiles.bak"
[[ -d $backup_dir ]] || mkdir "$backup_dir"

os=`uname`
if [[ $os != 'Darwin' ]]; then
  os_id=`sed -n 's/^ID=\(.*\)$/\1/p' /etc/os-release`
  os_id_like=`sed -n 's/^ID_LIKE=\(.*\)$/\1/p' /etc/os-release`
fi

function log() {
  echo "  ○ $@"
}

function command_exist() {
  command -v "$1" &> /dev/null
}

function backup() {
  local name="$1"
  local source_file="$HOME/$name"
  local dest_file="$backup_dir/$name"
  local bak_dir="$backup_dir"

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

function link_file() {
  local name="$1"
  if [[ "/" = ${name:0-1:1} ]]; then
    name="${name%?}"
  fi

  local bottle_file="$bottle_dir/$name"
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

function restore_file() {
  local name="$1"
  if [[ "/" = ${name:0-1:1} ]]; then
    name="${name%?}"
  fi

  local bak_file="$backup_dir/$name"
  local origin_file="$HOME/$name"
  local bottle_file="$bottle_dir/$name"

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

