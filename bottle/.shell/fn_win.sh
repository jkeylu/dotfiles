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
