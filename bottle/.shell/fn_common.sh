_path_add() {
	local p="$1"
	[[ -z "$p" || ":$PATH:" == *":$p:"* ]] && return 0
	export PATH="$p:$PATH"
}

_path_remove() {
	local p="$1"
	[[ -z "$p" ]] && return 1
	export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "^${p}$" | tr '\n' ':' | sed 's/:$//')
}

# ssh agent
SSH_AGENT_ENV="$HOME/.ssh/agent.env"
_ssh_agent_start() {
  ssh-agent -t "${SSH_AGENT_LIFETIME:-14h}" | sed 's/^echo/#echo/' > "$SSH_AGENT_ENV"
  chmod 600 "$SSH_AGENT_ENV"
  . "$SSH_AGENT_ENV" > /dev/null
}

_ssh_agent_check() {
  if [[ -n "$SSH_AGENT_PID" ]]; then
    local username="$USERNAME"
    if [[ -z $username ]]; then
      username="$(whoami)"
    fi
    ps -f -u "$username" | grep "$SSH_AGENT_PID" | grep -q ssh-agent
    if [[ $? -ne 0 ]]; then
      _ssh_agent_start
    fi
  else
    if [[ -s "$SSH_AGENT_ENV" ]]; then
      . "$SSH_AGENT_ENV" > /dev/null
      _ssh_agent_check
    else
      _ssh_agent_start
    fi
  fi
}

nvm() {
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    source "$NVM_DIR/nvm.sh"  # This loads nvm
    [[ -r "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
    nvm "$@"
  else
    echo "nvm is not installed"
  fi
}

proxy_on() {
  export http_proxy="http://${MY_PROXY_HOST:-127.0.0.1}:${MY_PROXY_PORT:-7890}"
  export HTTPS_PROXY="http://${MY_PROXY_HOST:-127.0.0.1}:${MY_PROXY_PORT:-7890}"
  export ALL_PROXY="socks5://${MY_PROXY_HOST:-127.0.0.1}:${MY_PROXY_PORT:-7890}"
  echo "Proxy is ON"
}

proxy_off() {
  unset http_proxy
  unset HTTPS_PROXY
  unset ALL_PROXY
  echo "Proxy is OFF"
}

chvimrc() {
  if [[ -z $1 || ($1 != "l" && $1 != "s") ]]; then
    echo "Usage: chvimrc [l|s]"
    echo "Current vimrc version is: "
    ls -G -l ~/.vimrc

  else
    if [[ $1 = "l" ]]; then
      ln -f -s ~/.vim/lite.vim ~/.vimrc

    elif [[ $1 = "s" ]]; then
      ln -f -s ~/.vim/simple.vim ~/.vimrc
    fi

    echo ".vimrc has been switched to: "
    ls -G -l ~/.vimrc
  fi
}

lvim() {
  vim -u ~/.vim/lite.vim "$@"
}

itmux() {
  if ! tmux ls &> /dev/null; then
    tmux new -s Default
  elif ! tmux ls | grep --quiet '(attached)'; then
    tmux attach -t Default || tmux new -s Default
  fi
}

if [[ -d "$HOME/.local/miniforge3" ]]; then
  conda() {
    unset -f conda

    # !! Contents within this block are managed by 'conda init' !!
    __conda_setup="$("$HOME/.local/miniforge3/bin/conda" shell.zsh hook 2> /dev/null)"
    if [ $? -eq 0 ]; then
      eval "$__conda_setup"
    else
      if [ -f "$HOME/.local/miniforge3/etc/profile.d/conda.sh" ]; then
        . "$HOME/.local/miniforge3/etc/profile.d/conda.sh"
      else
        export PATH="$HOME/.local/miniforge3/bin:$PATH"
      fi
    fi
    unset __conda_setup

    conda "$@"
  }

  mamba() {
    unset -f mamba

    # !! Contents within this block are managed by 'mamba shell init' !!
    export MAMBA_EXE="$HOME/.local/miniforge3/bin/mamba";
    export MAMBA_ROOT_PREFIX="$HOME/.local/miniforge3";
    __mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
    if [ $? -eq 0 ]; then
      eval "$__mamba_setup"
    else
      alias mamba="$MAMBA_EXE"  # Fallback on help from mamba activate
    fi
    unset __mamba_setup

    mamba "$@"
  }
fi
