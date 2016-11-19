# .bashrc

# Source global definitions
if [[ -f /etc/bashrc ]]; then
  . /etc/bashrc
fi

# User specific aliases and functions

export PATH=$HOME/.bin:$HOME/bin:/usr/local/bin:$PATH

if command -v vim &> /dev/null; then
  export EDITOR='vim'
else
  export EDITOR='vi'
fi

# alias
[[ -f ~/.shell_alias ]] && source ~/.shell_alias
[[ -f ~/.shell_alias_private ]] && source ~/.shell_alias_private

# shell functions
[[ -f ~/.shell_function ]] && source ~/.shell_function
[[ -f ~/.shell_function_private ]] && source ~/.shell_function_private

# disable CTRL-D to close window
set -o ignoreeof

[[ -f ~/.fzf.bash ]] && (source ~/.fzf.bash &> /dev/null || echo ".fzf.bash is somthing wrong")

# vim:ft=sh et ts=2 sw=2 sts=2
