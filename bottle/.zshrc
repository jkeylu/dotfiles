# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
if [[ $(uname -s) = "Darwin" ]]; then
  ZSH_THEME="robbyrussell"
else
  ZSH_THEME="gentoo"
fi

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git z sudo brew npm osx)

# User configuration

export PATH=$HOME/.bin:$HOME/bin:/usr/local/bin:$PATH
# export MANPATH="/usr/local/man:$MANPATH"

source $ZSH/oh-my-zsh.sh

# You may need to manually set your language environment
# export LANG=en_US.UTF-8
export LANG=zh_CN.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi
if command -v vim >/dev/null 2>&1; then
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
[[ -f ~/.shell_alias ]] && source ~/.shell_alias
[[ -f ~/.shell_alias_private ]] && source ~/.shell_alias_private

# shell functions
[[ -f ~/.shell_function ]] && source ~/.shell_function
[[ -f ~/.shell_function_private ]] && source ~/.shell_function_private

# disable CTRL-D to close window
set -o ignoreeof

# vimx
[[ -r ~/.vim/vimx.sh ]] && source ~/.vim/vimx.sh

# nvm
export NVM_DIR=$HOME/.nvm
export NVM_NODEJS_ORG_MIRROR=http://npm.taobao.org/mirrors/node
[[ -s $NVM_DIR/nvm.sh ]] && source $NVM_DIR/nvm.sh  # This loads nvm
[[ -r $NVM_DIR/bash_completion ]] && source $NVM_DIR/bash_completion

# fzf
[[ -f ~/.fzf.zsh ]] && (source ~/.fzf.zsh &> /dev/null || echo ".fzf.zsh is somthing wrong")

# go
export GOPATH=$HOME/Projects/gocode
export PATH=$GOPATH/bin:$PATH

# electron
export ELECTRON_MIRROR=http://npm.taobao.org/mirrors/electron/

# shadowsocks function chss
[[ -f ~/.config/shadowsocks/chss.sh ]] && source ~/.config/shadowsocks/chss.sh


# vim:ft=sh et ts=2 sw=2 sts=2