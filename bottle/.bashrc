# .bashrc

export DOTFILES_HOME="$HOME/.dotfiles"
export DOTFILES_BOTTLE="$DOTFILES_HOME/bottle"

[[ -f "$HOME/.shell_rc_pre.sh" ]] && source "$HOME/.shell_rc_pre.sh"

source "$DOTFILES_BOTTLE/.shell/fn_common.sh"

if [[ "${ENABLE_SSH_AGENT:-1}" == "1" ]] && ([[ -z "$SSH_CLIENT" ]] && [[ -z "$SSH_TTY" ]]); then
  _ssh_agent_check
fi

source "$DOTFILES_BOTTLE/.shell/rc_common.sh"
source "$DOTFILES_BOTTLE/.shell/alias.sh"

[[ -f "$HOME/.shell_rc.sh" ]] && source "$HOME/.shell_rc.sh"

# fzf
if [[ "${FZF_AUTO_COMPLETION:-1}" != "0" ]] && (command -v fzf &> /dev/null); then
  eval "$(fzf --bash)"
fi

# vim:ft=sh et ts=2 sw=2 sts=2
