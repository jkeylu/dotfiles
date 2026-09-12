#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
OPENER_DIR="$DOTFILES_DIR/opener"
PROGRAM_NAME="${0##*/}"

show_usage() {
  cat <<EOF
usage: $PROGRAM_NAME <command> [arguments]

commands:
  help [name]                    show general or component help
  list                           list available components
  install <name>                 install one component
  uninstall <name>               uninstall one component
  run <name> <action> [args...]  run a supported component action

examples:
  $PROGRAM_NAME list
  $PROGRAM_NAME help nvm
  $PROGRAM_NAME install zsh
  $PROGRAM_NAME uninstall brew
  $PROGRAM_NAME run nvm update
EOF
}

error() {
  printf 'Error: %s\n' "$*" >&2
}

validate_component() {
  local component="$1"

  if [[ ! "$component" =~ ^[a-z0-9][a-z0-9_-]*$ ]]; then
    error "invalid component name '$component'"
    return 2
  fi
}

run_opener() {
  local component="$1"
  local action="$2"
  shift 2

  validate_component "$component"

  local script="$OPENER_DIR/$component.sh"
  if [[ ! -f "$script" ]]; then
    error "unknown component '$component'; run '$PROGRAM_NAME list' to see available components"
    return 2
  fi

  bash "$script" "$action" "$@"
}

list_openers() {
  local script
  local name

  for script in "$OPENER_DIR"/*.sh; do
    [[ -f "$script" ]] || continue
    name="${script##*/}"
    printf '%s\n' "${name%.sh}"
  done
}

expect_exact_args() {
  local expected="$1"
  local actual="$2"
  local usage="$3"

  if ((actual != expected)); then
    error "usage: $PROGRAM_NAME $usage"
    return 2
  fi
}

main() {
  if (($# == 0)); then
    show_usage
    return 0
  fi

  local command_name="$1"
  shift

  case "$command_name" in
    help)
      if (($# == 0)); then
        show_usage
      elif (($# == 1)); then
        run_opener "$1" help
      else
        error "usage: $PROGRAM_NAME help [name]"
        return 2
      fi
      ;;
    list)
      expect_exact_args 0 "$#" list
      list_openers
      ;;
    install)
      expect_exact_args 1 "$#" 'install <name>'
      run_opener "$1" install
      ;;
    uninstall)
      expect_exact_args 1 "$#" 'uninstall <name>'
      run_opener "$1" uninstall
      ;;
    run)
      if (($# < 2)); then
        error "usage: $PROGRAM_NAME run <name> <action> [args...]"
        return 2
      fi
      local component="$1"
      local action="$2"
      shift 2
      run_opener "$component" "$action" "$@"
      ;;
    *)
      error "unknown command '$command_name'"
      show_usage >&2
      return 2
      ;;
  esac
}

main "$@"
