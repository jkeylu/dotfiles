alias ..='cd ..'
alias ...='cd ../..'

# edit shell config
alias editzshrc="$EDITOR ~/.zshrc"
alias editbashrc="$EDITOR ~/.bashrc"

# dotfiles/biu.sh
alias dotfilebiu="~/.dotfiles/biu.sh"

# proxy
alias all_proxy="ALL_PROXY=socks5://${MY_PROXY_HOST:-127.0.0.1}:${MY_PROXY_PORT:-7890}"
alias proxy_it="http_proxy=http://${MY_PROXY_HOST:-127.0.0.1}:${MY_PROXY_PORT:-7890} HTTPS_PROXY=http://${MY_PROXY_HOST:-127.0.0.1}:${MY_PROXY_PORT:-7890}"

# cnpm
if ! command -v cnpm &> /dev/null; then
  alias cnpm="npm \
              --registry=https://registry.npmmirror.com \
              --cache=$HOME/.npm/.cache/cnpm \
              --disturl=https://npmmirror.com/mirrors/node \
              --userconfig=$HOME/.cnpmrc"
fi

# in mintty on Git Bash
if [[ $- == *i* && "$MSYSTEM" == "MINGW64" && "$TERM" == xterm* ]] && (command -v winpty &> /dev/null); then
  alias node="winpty node"
  alias python="winpty python"
fi

# vim:ft=sh et ts=2 sw=2 sts=2
