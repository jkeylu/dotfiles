# .bashrc

# WSL
if [[ -f /proc/version ]]; then
  if cat /proc/version | grep --silent 'Microsoft'; then
    if [[ -t 1 ]]; then
      exec zsh
    fi
  fi
fi

# Source global definitions
if [[ -f /etc/bashrc ]]; then
  source /etc/bashrc
fi


# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
  xterm-color|*-256color) color_prompt=yes;;
esac

if [ "$color_prompt" = yes ]; then
  PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
elif [ -z "$MSYSTEM" ]; then
  PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
  PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
  ;;
*)
  ;;
esac


# ssh agent
SSH_AGENT_ENV="$HOME/.ssh/agent.env"
ssh_agent_start() {
  ssh-agent | sed 's/^echo/#echo/' > "$SSH_AGENT_ENV"
  chmod 600 "$SSH_AGENT_ENV"
  . "$SSH_AGENT_ENV" > /dev/null
}

ssh_agent_check() {
  if [ -n "$SSH_AGENT_PID" ]; then
    local username="$USERNAME"
    if [ -z $username ]; then
      username="$(whoami)"
    fi
    ps -f -u "$username" | grep "$SSH_AGENT_PID" | grep -q ssh-agent
    if [ $? -ne 0 ]; then
      ssh_agent_start
    fi
  else
    if [ -f "$SSH_AGENT_ENV" ]; then
      . "$SSH_AGENT_ENV" > /dev/null
      ssh_agent_check

    else
      ssh_agent_start
    fi
  fi
}

[ -f ~/.bash_start.sh ] && source ~/.bash_start.sh

if [ "$DISABLE_SSH_AGENT" = "1" ]; then
  ssh_agent_check
fi


# User configuration

source $HOME/.shell_rc.sh

# fzf
[[ -f ~/.fzf.bash ]] && (source ~/.fzf.bash &> /dev/null || echo ".fzf.bash is somthing wrong")

# vim:ft=sh et ts=2 sw=2 sts=2
