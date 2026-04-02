# .bashrc

export DOTFILES_HOME="$HOME/.dotfiles"
export DOTFILES_BOTTLE="$DOTFILES_HOME/bottle"

[[ -f "$HOME/.shell_rc_pre.sh" ]] && source "$HOME/.shell_rc_pre.sh"

source "$DOTFILES_BOTTLE/.shell/fn_common.sh"

if [[ "$ENABLE_SSH_AGENT" == "1" ]] || ([[ -z "$SSH_CLIENT" ]] && [[ -z "$SSH_TTY" ]]); then
  _ssh_agent_check
fi

source "$DOTFILES_BOTTLE/.shell/rc_common.sh"
source "$DOTFILES_BOTTLE/.shell/alias.sh"

[[ -f "$HOME/.shell_rc.sh" ]] && source "$HOME/.shell_rc.sh"

# fzf
[[ -f ~/.fzf.bash ]] && (source ~/.fzf.bash &> /dev/null || echo ".fzf.bash is somthing wrong")

# vim:ft=sh et ts=2 sw=2 sts=2
