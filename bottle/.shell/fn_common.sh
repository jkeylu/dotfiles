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

nvm() {
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    source "$NVM_DIR/nvm.sh"  # This loads nvm
    [[ -r "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
    nvm $@
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
