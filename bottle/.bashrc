# .bashrc

# Source global definitions
if [[ -f /etc/bashrc ]]; then
  source /etc/bashrc
fi

export PATH=$HOME/bin:/usr/local/bin:$PATH

# User configuration

source $HOME/.shell_rc

# fzf
[[ -f ~/.fzf.bash ]] && (source ~/.fzf.bash &> /dev/null || echo ".fzf.bash is somthing wrong")

# vim:ft=sh et ts=2 sw=2 sts=2
