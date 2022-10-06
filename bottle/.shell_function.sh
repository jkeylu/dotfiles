
nvm() {
  if [[ -s $NVM_DIR/nvm.sh ]]; then
    source $NVM_DIR/nvm.sh  # This loads nvm
    [[ -r $NVM_DIR/bash_completion ]] && source $NVM_DIR/bash_completion
    nvm $@
  else
    echo "nvm is not installed"
  fi
}

nvminstall() {
  local ver=`nvm current`
  nvm install "$1" --reinstall-packages-from="$ver" --latest-npm
}

itmux() {
  if ! tmux ls &> /dev/null; then
    tmux new -s Default
  elif ! tmux ls | grep --quiet '(attached)'; then
    tmux attach -t Default || tmux new -s Default
  fi
}

if [[ `uname` =~ "Darwin" ]]; then
  code () { VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args $*; }

  switchNetworkProxy() {
    local service="$1"
    local state="$2"

    if [[ -z $service ]]; then
      networksetup -listnetworkserviceorder
      return
    fi

    if [[ -z $state ]]; then
      networksetup -getsocksfirewallproxy "$service"
      return
    fi

    if [[ $state != 'on' && $state != 'off' ]]; then
      echo setNetworkProxy [service] [on|off]
      return
    fi

    networksetup -setsocksfirewallproxystate "$service" "$state"

    echo Change state to
    networksetup -getsocksfirewallproxy "$service" | grep '^Enabled:'
  }

  switchWifiProxy() {
    switchNetworkProxy "Wi-Fi" "$1"

    if [[ -z $1 ]]; then
      echo "\n=> Usage: switchWifiProxy [on|off]"
      return
    fi
  }
fi

# vim:ft=sh et ts=2 sw=2 sts=2
