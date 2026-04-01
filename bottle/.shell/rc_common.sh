# User configuration

if [[ ":$PATH:" != *":$HOME/.bin:"* ]]; then
  export PATH=$HOME/.bin:$PATH
fi

# Set system language to Chinese UTF-8
export LANG=zh_CN.UTF-8
# Set all locale categories to Chinese UTF-8
export LC_ALL=zh_CN.UTF-8
# Set less pager to use UTF-8 encoding
export LESSCHARSET=utf-8

# Preferred editor
if command -v vim &> /dev/null; then
  export EDITOR='vim'
else
  export EDITOR='vi'
fi

# disable CTRL-D to close window
set -o ignoreeof

# vimx
[[ -r ~/.vim/vimx.sh ]] && source ~/.vim/vimx.sh

# nvm
export NVM_DIR=$HOME/.nvm
export NVM_NODEJS_ORG_MIRROR=https://cdn.npmmirror.com/binaries/node
#[[ -s $NVM_DIR/nvm.sh ]] && source $NVM_DIR/nvm.sh  # This loads nvm
#[[ -r $NVM_DIR/bash_completion ]] && source $NVM_DIR/bash_completion
if [[ -f $NVM_DIR/alias/default ]]; then
  if [[ -d $NVM_DIR/versions/node/v$(cat $NVM_DIR/alias/default)/bin ]]; then
    export PATH=$NVM_DIR/versions/node/v$(cat $NVM_DIR/alias/default)/bin:$PATH
  fi
fi

# go
[[ -s $HOME/.gvm/gvm.sh ]] && source $HOME/.gvm/gvm.sh

# rust
if [[ -d $HOME/.cargo ]]; then
  export PATH=$HOME/.cargo/bin:$PATH
fi

# electron
export ELECTRON_MIRROR=https://npmmirror.com/mirrors/electron/

# puppeteer
export PUPPETEER_DOWNLOAD_HOST=https://npmmirror.com/mirrors/

# vim:ft=sh et ts=2 sw=2 sts=2
