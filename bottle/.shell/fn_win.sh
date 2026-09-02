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

win_env_set() {
  local name="$1"
  local value="$2"

  if ! _win_env_name_valid "$name" || [[ $# -ne 2 ]]; then
    echo "Usage: win_env_set <name> <value>" >&2
    return 1
  fi

  _DOTFILES_WIN_ENV_NAME="$name" _DOTFILES_WIN_ENV_VALUE="$value" _win_powershell '[Environment]::SetEnvironmentVariable($env:_DOTFILES_WIN_ENV_NAME, $env:_DOTFILES_WIN_ENV_VALUE, [EnvironmentVariableTarget]::User)' || return
}

win_env_rm() {
  local name="$1"

  if ! _win_env_name_valid "$name" || [[ $# -ne 1 ]]; then
    echo "Usage: win_env_rm <name>" >&2
    return 1
  fi

  _DOTFILES_WIN_ENV_NAME="$name" _win_powershell '[Environment]::SetEnvironmentVariable($env:_DOTFILES_WIN_ENV_NAME, $null, [EnvironmentVariableTarget]::User)' || return
}

win_env_sync() {
  local name="$1"
  local value

  if [[ $# -ne 1 || ! "$name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
    echo "Usage: win_env_sync <bash-variable-name>" >&2
    return 1
  fi

  if [[ ! -v "$name" ]]; then
    echo "Error: Bash environment variable '$name' is not set" >&2
    return 1
  fi

  value="${!name}"

  # Convert POSIX path lists (PATH, PYTHONPATH, etc.) before single paths.
  # Existing Windows paths are already suitable for the Windows environment.
  if [[ "$value" != [a-zA-Z]:[\\/]* && "$value" != \\* ]]; then
    if [[ "$name" =~ [Pp][Aa][Tt][Hh]$ && "$value" == *:* ]]; then
      value="$(cygpath -wp "$value")" || return
    elif [[ "$value" == "~/"* ]]; then
      value="$(cygpath -aw "$HOME/${value#\~/}")" || return
    elif [[ "$value" == /* || "$value" == ./* || "$value" == ../* || -e "$value" ||
      ( "$value" == */* && "$value" != *://* ) ]]; then
      value="$(cygpath -aw "$value")" || return
    fi
  fi

  win_env_set "$name" "$value"
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

  _DOTFILES_WIN_PATH_ENTRY="$path" _win_powershell '
    foreach ($target in @([EnvironmentVariableTarget]::Machine, [EnvironmentVariableTarget]::User)) {
      $variables = [Environment]::GetEnvironmentVariables($target)
      foreach ($key in $variables.Keys) {
        if ($key -ine "Path") {
          [Environment]::SetEnvironmentVariable($key, $variables[$key], [EnvironmentVariableTarget]::Process)
        }
      }
    }

    function Expand-PathEntry([string]$value, [bool]$required) {
      for ($i = 0; $i -lt 10; $i++) {
        $expanded = [Environment]::ExpandEnvironmentVariables($value)
        if ($expanded -eq $value) { break }
        $value = $expanded
      }
      if ($required -and $value -match "%[^%]+%") {
        throw "Cannot resolve environment variable in path: $value"
      }
      return $value
    }

    $entry = Expand-PathEntry $env:_DOTFILES_WIN_PATH_ENTRY $true
    $current = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
    $items = @($current -split ";" | Where-Object { $_ -ne "" })
    $newItems = @()
    $found = $false
    $changed = $false

    foreach ($item in $items) {
      if ((Expand-PathEntry $item $false) -ieq $entry) {
        if (-not $found) {
          $newItems += $entry
          $found = $true
          if ($item -cne $entry) { $changed = $true }
        } else {
          $changed = $true
        }
      } else {
        $newItems += $item
      }
    }

    if (-not $found) {
      $newItems += $entry
      $changed = $true
    }
    if ($changed) {
      [Environment]::SetEnvironmentVariable("Path", ($newItems -join ";"), [EnvironmentVariableTarget]::User)
    }
  ' || return
}

win_path_rm() {
  local path="$1"

  if [[ -z "$path" || $# -ne 1 ]]; then
    echo "Usage: win_path_rm <path>" >&2
    return 1
  fi

  _DOTFILES_WIN_PATH_ENTRY="$path" _win_powershell '
    foreach ($target in @([EnvironmentVariableTarget]::Machine, [EnvironmentVariableTarget]::User)) {
      $variables = [Environment]::GetEnvironmentVariables($target)
      foreach ($key in $variables.Keys) {
        if ($key -ine "Path") {
          [Environment]::SetEnvironmentVariable($key, $variables[$key], [EnvironmentVariableTarget]::Process)
        }
      }
    }

    function Expand-PathEntry([string]$value, [bool]$required) {
      for ($i = 0; $i -lt 10; $i++) {
        $expanded = [Environment]::ExpandEnvironmentVariables($value)
        if ($expanded -eq $value) { break }
        $value = $expanded
      }
      if ($required -and $value -match "%[^%]+%") {
        throw "Cannot resolve environment variable in path: $value"
      }
      return $value
    }

    $entry = Expand-PathEntry $env:_DOTFILES_WIN_PATH_ENTRY $true
    $current = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
    if ($null -ne $current) {
      $items = @($current -split ";" | Where-Object {
        $_ -ne "" -and (Expand-PathEntry $_ $false) -ine $entry
      })
      $newValue = $items -join ";"
      [Environment]::SetEnvironmentVariable("Path", $(if ($newValue) { $newValue } else { $null }), [EnvironmentVariableTarget]::User)
    }
  ' || return
}

# Finds current-user Windows PATH entries that contain a given executable,
# excluding the executable's target directory.
#
# Arguments:
#   $1 - Executable name to search for. When it has no extension, PATHEXT
#        extensions are also checked.
#   $2 - Target Windows directory to exclude from the search results.
#
# Output:
#   Writes each matching PATH entry, in its original unexpanded form, to
#   standard output on a separate line. Produces no output when none match.
_win_path_command_entries() {
  local command="$1"
  local target_path="$2"

  _DOTFILES_WIN_COMMAND="$command" _DOTFILES_WIN_TARGET_PATH="$target_path" _win_powershell '
    foreach ($target in @([EnvironmentVariableTarget]::Machine, [EnvironmentVariableTarget]::User)) {
      $variables = [Environment]::GetEnvironmentVariables($target)
      foreach ($key in $variables.Keys) {
        if ($key -ine "Path") {
          [Environment]::SetEnvironmentVariable($key, $variables[$key], [EnvironmentVariableTarget]::Process)
        }
      }
    }

    function Expand-PathEntry([string]$value) {
      for ($i = 0; $i -lt 10; $i++) {
        $expanded = [Environment]::ExpandEnvironmentVariables($value)
        if ($expanded -eq $value) { break }
        $value = $expanded
      }
      $value = $value.TrimEnd([char[]]"\\/")
      if ($value -match "^[a-zA-Z]:$") { $value += "\\" }
      return $value
    }

    $command = $env:_DOTFILES_WIN_COMMAND
    $targetPath = (Expand-PathEntry $env:_DOTFILES_WIN_TARGET_PATH)
    $extensions = if ([IO.Path]::GetExtension($command)) {
      @("")
    } else {
      @("") + @($env:PATHEXT -split ";" | Where-Object { $_ -ne "" })
    }
    $current = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
    $seen = @{}

    foreach ($item in @($current -split ";" | Where-Object { $_ -ne "" })) {
      $expandedItem = Expand-PathEntry $item
      if ($expandedItem -ieq $targetPath -or $seen.ContainsKey($expandedItem)) { continue }

      foreach ($extension in $extensions) {
        $candidate = Join-Path -Path $expandedItem -ChildPath ($command + $extension)
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
          $seen[$expandedItem] = $true
          $item
          break
        }
      }
    }
  '
}

win_path_sync() {
  local command="$1"
  local executable_path
  local executable_dir
  local windows_dir
  local matches
  local old_path
  local reply

  if [[ $# -ne 1 || -z "$command" ]]; then
    echo "Usage: win_path_sync <bash-command-name>" >&2
    return 1
  fi

  executable_path="$(type -P -- "$command" 2>/dev/null)"
  if [[ -z "$executable_path" ]]; then
    echo "Error: Executable '$command' was not found in the Bash PATH" >&2
    return 1
  fi

  executable_dir="$(cd -P -- "$(dirname -- "$executable_path")" && pwd)" || return
  windows_dir="$(cygpath -aw "$executable_dir")" || return
  matches="$(_win_path_command_entries "$(basename -- "$command")" "$windows_dir")" || return

  if [[ -n "$matches" ]]; then
    while IFS= read -r old_path <&3; do
      old_path="${old_path%$'\r'}"
      [[ -z "$old_path" ]] && continue

      if ! read -r -p "Windows PATH entry '$old_path' also contains '$command'. Remove it? [y/N] " reply; then
        reply=""
      fi
      reply="${reply%$'\r'}"
      case "$reply" in
        [yY]|[yY][eE][sS])
          win_path_rm "$old_path" || return
          ;;
        *)
          echo "Kept Windows PATH entry: $old_path"
          ;;
      esac
    done 3<<< "$matches"
  fi

  win_path_add "$windows_dir"
}
