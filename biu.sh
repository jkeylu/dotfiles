#!/usr/bin/env bash

source util.sh

dotfiles="$__dir/dotfiles"

function show_usage() {
  cat << EOF
usage: ./biu.sh [option]

option:
  -i install dotfiles
  -r restore dotfiles
  -c run custom script
  -h show this help message
EOF
}

function install() {
  while read line; do
    [[ -z $line ]] && continue
    [[ "#" = ${line:0:1} ]] && continue

    link_file "$line"
  done < $dotfiles
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

[[ 0 = $# ]] && show_usage && exit 1

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
