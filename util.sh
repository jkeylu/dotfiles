#!/usr/bin/env bash

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
backup_dir="$HOME/.dotfiles.bak"

function log() {
  echo "  ○ $@"
}

function link_file() {
  local name="$1"
  local bak_dir="$backup_dir"
  if [[ "/" = ${name:0-1:1} ]]; then
    name="${name%?}"
    bak_dir="$bak_dir/$name"
    bak_dir="${bak_dir%/*}"
  fi

  local source_file="$__dir/box/$name"
  local link_name="$HOME/$name"

  if [[ -L $link_name ]]; then
    if [[ $(readlink "$link_name") = $source_file ]]; then
      log symbolic link $link_name already exists
      return
    fi
  fi

  if [[ -e $link_name ]]; then
    [[ -d $bak_dir ]] || mkdir -p "$bak_dir"

    log backup "$link_name"
    mv "$link_name" "$bak_dir"
  fi

  log ln -s "$source_file" "$link_name"
  ln -s "$source_file" "$link_name"
}

function restore_file() {
  local name="$1"
  if [[ "/" = ${name:0-1:1} ]]; then
    name="${name%?}"
  fi

  local backup_file="$backup_dir/$name"
  local origin_file="$HOME/$name"
  local source_file="$__dir/box/$name"

  if [[ ! -L $origin_file ]]; then
    return
  fi

  if [[ $(readlink "$origin_file") != $source_file ]]; then
    return
  fi

  log rm -rf $origin_file
  rm -rf $origin_file

  if [[ -e $backup_file ]]; then
    log restore "$origin_file"
    mv "$backup_file" "$origin_file"
  fi
}
