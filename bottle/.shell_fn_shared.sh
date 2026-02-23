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
