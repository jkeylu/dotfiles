#!/usr/bin/env bash

config_link="$HOME/.config/shadowsocks/config.json"

function chss() {
  local name="$1"
  local config="$HOME/.config/shadowsocks/$name.config.json"

  if [[ -z $name ]]; then
    echo "usage: \e[1;36mchss \e[1;0m config.json name in ~/.config/shadowsocks/*.config.json >"
    echo "       change shadowsocks server with one of the following configuration files "
    ls -G -l ~/.config/shadowsocks/*.json

  else
    if [[ ! -f $config ]]; then
      echo "Not found: $config"
      exit 1
    fi

    rm -f "$config_link"
    ln -s "$config" "$config_link"

    echo -e "unload shadowsocks-libev.plist"
    launchctl unload ~/Library/LaunchAgents/shadowsocks-libev.plist
    echo -e "load shadowsocks-libev.plist"
    launchctl load ~/Library/LaunchAgents/shadowsocks-libev.plist

    #killall ss-local
    #sudo networksetup -setwebproxystate Wi-Fi off
    #sudo networksetup -setsocksfirewallproxystate Wi-Fi off
    #sudo networksetup -setautoproxystate Wi-Fi off
    #echo -e "Wi-FI proxy has been turned off"
    #sudo networksetup -setautoproxystate Wi-Fi on
    #sudo networksetup -setautoproxyurl Wi-Fi http://localhost:8081/autoproxy.pac
    #echo -e "Wi-Fi proxy has been set to auto.pac"

    echo -e "Shadowsocks server has been switched to: "
    ls -G -l ~/.config/shadowsocks/config.json
  fi
}
