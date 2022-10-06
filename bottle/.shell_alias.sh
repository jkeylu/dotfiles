alias ..='cd ..'
alias ...='cd ../..'
alias zshconfig="$EDITOR ~/.zshrc"
alias myip="curl --silent ifconfig.me"

[[ -f /var/log/syslog ]] && alias syslog="tail -f /var/log/syslog -n30"

# dotfiles/biu.sh
alias dotfilebiu="~/.dotfiles/biu.sh"

# thefuck
[[ -e /usr/local/bin/thefuck ]] && eval "$(thefuck --alias)"

# proxy
alias all_proxy="ALL_PROXY=socks5://127.0.0.1:1080"
alias proxy_it="http_proxy=http://127.0.0.1:1080 HTTPS_PROXY=http://127.0.0.1:1080"

# cnpm
alias cnpm="npm \
            --registry=https://registry.npmmirror.com \
            --cache=$HOME/.npm/.cache/cnpm \
            --disturl=https://npmmirror.com/mirrors/node \
            --userconfig=$HOME/.cnpmrc"

# alias nightly_nvm="NVM_NODEJS_ORG_MIRROR=https://nodejs.org/download/nightly nvm"
alias taobao_nvm="NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node nvm"
# alias official_nvm="NVM_NODEJS_ORG_MIRROR=https://nodejs.org/dist nvm"

# vim:ft=sh et ts=2 sw=2 sts=2
