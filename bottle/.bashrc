# .bashrc

# WSL
if [[ -f /proc/version ]]; then
  if [[ cat /proc/version | grep --silent 'Microsoft' ]]; then
    if [[ -t 1 ]]; then
      exec zsh
    fi
  fi
fi

# Source global definitions
if [[ -f /etc/bashrc ]]; then
  source /etc/bashrc
fi

# User configuration

source $HOME/.shell_rc

# fzf
[[ -f ~/.fzf.bash ]] && (source ~/.fzf.bash &> /dev/null || echo ".fzf.bash is somthing wrong")

# vim:ft=sh et ts=2 sw=2 sts=2
