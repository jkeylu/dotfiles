alias ..='cd ..'
alias ...='cd ../..'
alias zshconfig="$EDITOR ~/.zshrc"
alias myip="curl --silent ifconfig.me"

[[ -f /var/log/syslog ]] && alias syslog="tail -f /var/log/syslog -n30"
[[ -f /usr/local/lib/node_modules/wake_on_lan/wake ]] && alias wake="/usr/local/lib/node_modules/wake_on_lan/wake"

alias start_mongod="mongod --config /usr/local/etc/mongod.conf"
alias start_elasticsearch="elasticsearch --config=/usr/local/opt/elasticsearch/config/elasticsearch.yml"

# dotfiles/biu.sh
alias dotfilebiu="~/.dotfiles/biu.sh"

# vim
alias v="vim --cmd \"let g:custom_env = ['zmlearn']\""
alias nv="nvim --cmd \"let g:custom_env = ['zmlearn']\""

# thefuck
[[ -e /usr/local/bin/thefuck ]] && eval "$(thefuck --alias)"

# proxy
alias all_proxy="ALL_PROXY=socks5://127.0.0.1:1080"
alias proxy_it="http_proxy=http://127.0.0.1:1080 HTTPS_PROXY=http://127.0.0.1:1080"

# cnpm
alias cnpm="npm \
            --registry=https://registry.npm.taobao.org \
            --cache=$HOME/.npm/.cache/cnpm \
            --disturl=https://npm.taobao.org/dist \
            --userconfig=$HOME/.cnpmrc"

alias nightly_nvm="NVM_NODEJS_ORG_MIRROR=https://nodejs.org/download/nightly nvm"
alias taobao_nvm="NVM_NODEJS_ORG_MIRROR=https://npm.taobao.org/mirrors/node nvm"
# alias official_nvm="NVM_NODEJS_ORG_MIRROR=https://nodejs.org/dist nvm"

# vim:ft=sh et ts=2 sw=2 sts=2
