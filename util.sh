#!/usr/bin/env bash

__util__=1
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

root_bakup_dir="$HOME/.dotfiles.bak"
[[ -d $root_bakup_dir ]] || mkdir "$root_bakup_dir"

function log() {
  echo "  ○ $@"
}

function backup() {
  local name="$1"
  local source_file="$HOME/$name"
  local backup_dir="$root_bakup_dir"

  if [[ "/" = ${name:0-1:1} ]]; then
    name="${name%?}"
    backup_dir="$backup_dir/$name"
    backup_dir="${backup_dir%/*}"
  fi

  if [[ -e $source_file ]]; then
    [[ -d $backup_dir ]] || mkdir -p "$backup_dir"

    log backup $source_file
    mv "$source_file" "$backup_dir"
  fi
}

function link_file() {
  local name="$1"
  if [[ "/" = ${name:0-1:1} ]]; then
    name="${name%?}"
  fi

  local boxed_file="$__dir/box/$name"
  local link_name="$HOME/$name"

  if [[ -L $link_name ]]; then
    if [[ $(readlink "$link_name") = $boxed_file ]]; then
      log symbolic link $link_name already created
      return
    fi
  fi

  backup "$1"

  log ln -s "$boxed_file" "$link_name"
  ln -s "$boxed_file" "$link_name"
}

function restore_file() {
  local name="$1"
  if [[ "/" = ${name:0-1:1} ]]; then
    name="${name%?}"
  fi

  local backup_file="$root_bakup_dir/$name"
  local origin_file="$HOME/$name"
  local boxed_file="$__dir/box/$name"

  if [[ ! -L $origin_file ]]; then
    return
  fi

  if [[ $(readlink "$origin_file") != $boxed_file ]]; then
    return
  fi

  log rm -rf $origin_file
  rm -rf $origin_file

  if [[ -e $backup_file ]]; then
    log restore "$origin_file"
    mv "$backup_file" "$origin_file"
  fi
}
