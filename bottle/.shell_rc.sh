# User configuration

if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
  export PATH=/usr/local/bin:$PATH
fi

if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
  export PATH=$HOME/bin:$PATH
fi

if [[ -d $HOME/.linuxbrew ]]; then
  export PATH="$HOME/.linuxbrew/bin:$PATH"
  export MANPATH="$HOME/.linuxbrew/share/man:$MANPATH"
  export INFOPATH="$HOME/.linuxbrew/share/info:$INFOPATH"
fi

export PATH=$HOME/.bin:$PATH
[[ -d $HOME/Dropbox ]] && export PATH=$HOME/Dropbox/usr/bin:$PATH
# export MANPATH="/usr/local/man:$MANPATH"

[[ -z $TMPDIR ]] && export TMPDIR=/tmp/

# You may need to manually set your language environment
# export LANG=en_US.UTF-8
export LANG=zh_CN.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi
if command -v vim &> /dev/null; then
  export EDITOR='vim'
else
  export EDITOR='vi'
fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
[[ -f ~/.shell_alias.sh ]] && source ~/.shell_alias.sh
[[ -f ~/.shell_alias_private.sh ]] && source ~/.shell_alias_private.sh

# shell functions
[[ -f ~/.shell_function.sh ]] && source ~/.shell_function.sh
[[ -f ~/.shell_function_private.sh ]] && source ~/.shell_function_private.sh

# disable CTRL-D to close window
set -o ignoreeof

# vimx
[[ -r ~/.vim/vimx.sh ]] && source ~/.vim/vimx.sh

# brew
export HOMEBREW_NO_AUTO_UPDATE=1

# nvm
export NVM_DIR=$HOME/.nvm
export NVM_NODEJS_ORG_MIRROR=http://npm.taobao.org/mirrors/node
#[[ -s $NVM_DIR/nvm.sh ]] && source $NVM_DIR/nvm.sh  # This loads nvm
#[[ -r $NVM_DIR/bash_completion ]] && source $NVM_DIR/bash_completion
if [[ -f $NVM_DIR/alias/default ]]; then
  if [[ -d $NVM_DIR/versions/node/v$(cat $NVM_DIR/alias/default)/bin ]]; then
    PATH=$NVM_DIR/versions/node/v$(cat $NVM_DIR/alias/default)/bin:$PATH
  fi
fi

# python
if command -v python3 &> /dev/null; then
  export PATH="$(python3 -m site --user-base)/bin:$PATH"
else
  export PATH="$(python -m site --user-base)/bin:$PATH"
fi

# go
if command -v go &> /dev/null; then
  export GOPATH=$HOME/Projects/go
  export PATH=$GOPATH/bin:$PATH
fi

# rust
if [[ -d $HOME/.cargo ]]; then
  export PATH=$HOME/.cargo/bin:$PATH
fi

# electron
export ELECTRON_MIRROR=http://npm.taobao.org/mirrors/electron/

# puppeteer
export PUPPETEER_DOWNLOAD_HOST=https://npm.taobao.org/mirrors/

# vim:ft=sh et ts=2 sw=2 sts=2
