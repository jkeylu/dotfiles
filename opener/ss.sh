#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

launch_agents="$HOME/Library/LaunchAgents"
plist="$config_dir/shadowsocks/ss-local.plist"
plist_link="$launch_agents/ss-local.plist"
kcptun_plist="$config_dir/shadowsocks/kcptun-client.plist"
kcptun_plist_link="$launch_agents/kcptun-client.plist"

function install() {
    link_file .config/shadowsocks/
    link_file .bin/ssc.svc

    if [[ $os = "Darwin" ]]; then
        [[ -d $launch_agents ]] || mkdir -p "$launch_agents"

        if ! command_exist kcptun-client; then
            bash "$opener_dir/kcptun" -i
        fi

        if ! command_exist ss-local; then
            command_exist brew || log "brew is not installed" && exit 1
            brew install shadowsocks-libev
        fi

        if [[ ! -e $kcptun_plist ]]; then
            log "create $kcptun_plist"
            cat > "$kcptun_plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
    <key>Label</key>
    <string>lu.jkey.kcptun-client</string>
    <key>ProgramArguments</key>
    <array>
        <string>${bin_dir}/ssc.svc</string>
        <string>start</string>
        <string>kcptun-client</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>${bin_dir}:/bin:/usr/bin:/usr/local/bin</string>
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${cache_dir}/shadowsocks/kcptun-client.stdout</string>
    <key>StandardErrorPath</key>
    <string>${cache_dir}/shadowsocks/kcptun-client.stderr</string>
    </dict>
</plist>
EOF
        fi

        if [[ ! -e $plist ]]; then
            log "create $plist"
            cat > "$plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
    <key>Label</key>
    <string>lu.jkey.ss-local</string>
    <key>ProgramArguments</key>
    <array>
        <string>${bin_dir}/ssc.svc</string>
        <string>start</string>
        <string>ss-local</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>${bin_dir}:/bin:/usr/bin:/usr/local/bin</string>
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${cache_dir}/shadowsocks/ss-local.stdout</string>
    <key>StandardErrorPath</key>
    <string>${cache_dir}/shadowsocks/ss-local.stderr</string>
    </dict>
</plist>
EOF
        fi

        if [[ -e $kcptun_plist_link ]]; then
            log "$kcptun_plist_link is already exists"

        else
            log ln -s "$kcptun_plist" "$kcptun_plist_link"
            ln -s "$kcptun_plist" "$kcptun_plist_link"
            echo -e "please run \033[0;32mlaunchctl load $kcptun_plist_link\033[0m"
        fi

        if [[ -e $plist_link ]]; then
            log "$plist_link is already exists"
        else

            log ln -s "$plist" "$plist_link"
            ln -s "$plist" "$plist_link"
            echo -e "please run \033[0;32mlaunchctl load $plist_link\033[0m"
        fi
    fi
}

function uninstall() {
    if [[ $os = "Darwin" ]]; then
        launchctl unload "$kcptun_plist_link"
        launchctl unload "$plist_link"
        rm "$kcptun_plist_link"
        rm "$kcptun_plist"
        rm "$plist_link"
        rm "$plist"
    fi
}

[[ 0 = $# || "-i" = $1 ]] && install && exit 0
[[ "-u" = $1 ]] && uninstall && exit 0
exit 1

