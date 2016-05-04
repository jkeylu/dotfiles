#!/usr/bin/env bash

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

dotfiles="$__dir/dotfiles"
backup_dir="$HOME/.dotfiles.bak"

mkdir -p "$backup_dir"

function log() {
  echo "  ○ $@"
}

function show_usage() {
  echo "Hello world"
}

function link_file() {
  local name="$1"
  if [[ "/" = ${name:0-1:1} ]]; then
    name="${name%?}"
  fi

  local source_file="$__dir/box/$name"
  local link_name="$HOME/$name"

  if [[ -L $link_name ]]; then
    if [[ $(readlink "$link_name") = $source_file ]]; then
      return
    fi
  fi

  if [[ -e $link_name ]]; then
    log backup "$link_name"
    mv "$link_name" "$backup_dir"
  fi

  log ln -s "$source_file" "$link_name"
  ln -s "$source_file" "$link_name"
}

function install() {
  while read line; do
    [[ -z $line ]] && continue
    [[ "#" = ${line:0:1} ]] && continue

    link_file "$line"
  done < $dotfiles
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

function restore() {
  while read line; do
    [[ -z $line ]] && continue
    [[ "#" = ${line:0:1} ]] && continue

    restore_file "$line"
  done < $dotfiles
}

function run_custom() {
  local script="${__dir}/custom/${1}.sh"

  if [[ -f "$script" ]]; then
    bash "$script"
  else
    echo "script \"$script\" not found!"
  fi
}

while :; do
  [[ -z $1 ]] && break;

  case "$1" in
    -h|--help)
      show_usage
      exit 0
      ;;
    -i|--install)
      install
      exit 0
      ;;
    -r|--restore)
      restore
      exit 0
      ;;
    -c|--custom)
      run_custom "$2"
      exit 0
      ;;
    *)
      echo -e "\033[31mERROR: unknown argument! \033[0m\n"
      show_usage
      exit 1
      ;;
  esac
done
