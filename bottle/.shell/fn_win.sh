# python version manager for windows
_pvm_ls() {
  ls "$(cygpath -u "$LOCALAPPDATA")/Programs/Python" | grep '^Python' | sed 's/^Python//' | sed 's/\/$//'
}

_pvm_use() {
  local version="$1"

  if [[ -z "$version" ]]; then
    echo "Usage: pvm use <version>"
    return 1
  fi

  if [[ -n "$PYTHON_HOME" ]]; then
    _pvm_unuse
  fi

  local python_path="$(cygpath -u "$LOCALAPPDATA")/Programs/Python/Python$version"

  if [[ ! -d "$python_path" ]]; then
    echo "Error: Python version $version not found at $python_path"
    return 1
  fi

  export PYTHON_HOME="$python_path"
  _path_add "$PYTHON_HOME"
  _path_add "$PYTHON_HOME/Scripts"

  echo "Activated Python $version at $PYTHON_HOME"
}

_pvm_unuse() {
  if [[ -n "$PYTHON_HOME" ]]; then
    _path_remove "$PYTHON_HOME/Scripts"
    _path_remove "$PYTHON_HOME"

    echo "Deactivated Python at $PYTHON_HOME"

    unset PYTHON_HOME
  fi
}

_pvm_act() {
  if [[ -d "$(pwd)/.venv" ]]; then
    source "$(pwd)/.venv/Scripts/activate"
  elif [[ -d "$(pwd)/venv" ]]; then
    source "$(pwd)/venv/Scripts/activate"
  else
    echo "Error: No venv or .venv folder found in current directory"
    return 1
  fi
}

pvm() {
  local command="$1"

  case "$command" in
    ls)
      _pvm_ls
      ;;
    use)
      _pvm_use "$2"
      ;;
    unuse)
      _pvm_unuse
      ;;
    act)
      _pvm_act
      ;;
    *)
      echo "Usage: pvm <list|use|unuse|act> ..."
      ;;
  esac
}

# Windows current-user environment variables. Changes are persistent and take
# effect in newly started Windows processes; the current Bash process is also
# updated when the variable name is a valid shell identifier.
_win_powershell() {
  powershell.exe -NoProfile -NonInteractive -Command "$1"
}

_win_env_name_valid() {
  [[ -n "$1" && "$1" != *"="* ]]
}

_win_env_sync_current_shell() {
  local name="$1"
  local value="$2"

  # Windows PATH uses semicolons, so never replace Bash's colon-separated PATH.
  [[ "$name" =~ ^[Pp][Aa][Tt][Hh]$ ]] && return 0

  if [[ "$name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
    export "$name=$value"
  fi
}

win_env_add() {
  local name="$1"
  local value="$2"

  if ! _win_env_name_valid "$name" || [[ $# -ne 2 ]]; then
    echo "Usage: win_env_add <name> <value>" >&2
    return 1
  fi

  _DOTFILES_WIN_ENV_NAME="$name" _DOTFILES_WIN_ENV_VALUE="$value" _win_powershell '[Environment]::SetEnvironmentVariable($env:_DOTFILES_WIN_ENV_NAME, $env:_DOTFILES_WIN_ENV_VALUE, [EnvironmentVariableTarget]::User)' || return
  _win_env_sync_current_shell "$name" "$value"
}

win_env_rm() {
  local name="$1"

  if ! _win_env_name_valid "$name" || [[ $# -ne 1 ]]; then
    echo "Usage: win_env_rm <name>" >&2
    return 1
  fi

  _DOTFILES_WIN_ENV_NAME="$name" _win_powershell '[Environment]::SetEnvironmentVariable($env:_DOTFILES_WIN_ENV_NAME, $null, [EnvironmentVariableTarget]::User)' || return

  if [[ ! "$name" =~ ^[Pp][Aa][Tt][Hh]$ && "$name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
    unset "$name"
  fi
}

win_env() {
  local name="$1"

  if [[ $# -gt 1 ]] || { [[ $# -eq 1 ]] && ! _win_env_name_valid "$name"; }; then
    echo "Usage: win_env [name]" >&2
    return 1
  fi

  if [[ $# -eq 1 ]]; then
    _DOTFILES_WIN_ENV_NAME="$name" _win_powershell '$name = $env:_DOTFILES_WIN_ENV_NAME; $value = [Environment]::GetEnvironmentVariable($name, [EnvironmentVariableTarget]::User); if ($null -ne $value) { "{0}={1}" -f $name, $value }'
  else
    _win_powershell '[Environment]::GetEnvironmentVariables([EnvironmentVariableTarget]::User).GetEnumerator() | Sort-Object Name | ForEach-Object { "{0}={1}" -f $_.Key, $_.Value }'
  fi
}

win_path() {
  if [[ $# -ne 0 ]]; then
    echo "Usage: win_path" >&2
    return 1
  fi

  _win_powershell '$current = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User); if ($null -ne $current) { $current -split ";" | Where-Object { $_ -ne "" } }'
}

win_path_add() {
  local path="$1"

  if [[ -z "$path" || $# -ne 1 ]]; then
    echo "Usage: win_path_add <path>" >&2
    return 1
  fi

  _DOTFILES_WIN_PATH_ENTRY="$path" _win_powershell '$entry = $env:_DOTFILES_WIN_PATH_ENTRY; $current = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User); $items = @($current -split ";" | Where-Object { $_ -ne "" }); if (-not ($items | Where-Object { $_ -ieq $entry })) { $items += $entry; [Environment]::SetEnvironmentVariable("Path", ($items -join ";"), [EnvironmentVariableTarget]::User) }'
}

win_path_rm() {
  local path="$1"

  if [[ -z "$path" || $# -ne 1 ]]; then
    echo "Usage: win_path_rm <path>" >&2
    return 1
  fi

  _DOTFILES_WIN_PATH_ENTRY="$path" _win_powershell '$entry = $env:_DOTFILES_WIN_PATH_ENTRY; $current = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User); if ($null -ne $current) { $items = @($current -split ";" | Where-Object { $_ -ne "" -and $_ -ine $entry }); $newValue = $items -join ";"; [Environment]::SetEnvironmentVariable("Path", $(if ($newValue) { $newValue } else { $null }), [EnvironmentVariableTarget]::User) }'
}

