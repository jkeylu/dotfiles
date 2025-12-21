
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

  condaon() {
    # >>> conda initialize >>>
    # !! Contents within this block are managed by 'conda init' !!
    __conda_setup="$('/usr/local/Caskroom/miniforge/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "/usr/local/Caskroom/miniforge/base/etc/profile.d/conda.sh" ]; then
            . "/usr/local/Caskroom/miniforge/base/etc/profile.d/conda.sh"
        else
            export PATH="/usr/local/Caskroom/miniforge/base/bin:$PATH"
        fi
    fi
    unset __conda_setup
    # <<< conda initialize <<<

    echo "Conda activated"
  }

  condaoff() {
    # 停用 conda 环境并移除相关路径
    conda deactivate 2>/dev/null
    # 从 PATH 中移除 conda 路径
    export PATH=$(echo $PATH | sed 's|/usr/local/Caskroom/miniforge/base/bin:||')

    echo "Conda deactivated"
  }

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
