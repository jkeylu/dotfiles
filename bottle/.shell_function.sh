function code () { VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args $*; }

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

if [[ $(uname -s) = "Darwin" ]]; then
  mynetworksetup() {
    case "$1" in
      ls)
        networksetup -listnetworkserviceorder
        ;;
      getsfp)
        networksetup -getsocksfirewallproxy "$2"
        ;;
      setsfp)
        networksetup -setsocksfirewallproxy "$2" "$3" "$4"
        ;;
      tgsfp)
        if networksetup -getsocksfirewallproxy "$2" | grep --quiet 'Enabled: Yes'; then
          networksetup -setsocksfirewallproxystate "$2" off
        else
          networksetup -setsocksfirewallproxystate "$2" on
        fi
        echo 'Change state to:'
        networksetup -getsocksfirewallproxy "$2" | grep '^Enabled:'
        ;;
      *)
        echo "mynetworksetup ls|getsfp|setsfp|tgsfp"
        ;;
    esac
  }
fi

# vim:ft=sh et ts=2 sw=2 sts=2
