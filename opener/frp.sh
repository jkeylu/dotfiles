#!/usr/bin/env bash

source "$HOME/.dotfiles/util.sh"

init_work_dir frp

help() {
  cat << EOF
supported commands:
  install
  update
  install_service [frpc|frps]
  pm2config [frpc|frps]
EOF
}

dl_filename=""
download() {
  local repo="fatedier/frp"
  local tag=`gh_latest_tag $repo`
  local version="${tag#v}"

  if [[ $OS == 'Darwin' ]]; then
    dl_filename="frp_${version}_darwin_amd64.tar.gz"
  elif [[ $OS == 'Linux' ]]; then
    if uname -m | grep --silent '64'; then
      dl_filename="frp_${version}_linux_amd64.tar.gz"
    elif uname -m | grep --silent '86'; then
      dl_filename="frp_${version}_linux_386.tar.gz"
    elif uname -m | grep --silent 'arm'; then
      dl_filename="frp_${version}_linux_arm.tar.gz"
    fi
  fi

  if [[ -z $dl_filename ]]; then
    echo "not supported system"
    exit 1
  fi

  gh_download $repo $tag $dl_filename
}

install() {
  download

  tar zxvf "${TMPDIR}${dl_filename}" -C "$BIN_DIR" --strip-components 1 '*frpc'
  tar zxvf "${TMPDIR}${dl_filename}" -C "$BIN_DIR" --strip-components 1 '*frps'
  tar zxvf "${TMPDIR}${dl_filename}" -C "$MY_CONFIG_DIR" --strip-components 1 '*frp*.ini'
}

update() {
  if [[ -x "$BIN_DIR/frpc" ]]; then
    log "current version: $($BIN_DIR/frpc --version)"
  fi

  download

  tar zxvf "${TMPDIR}${dl_filename}" -C "$BIN_DIR" --strip-components 1 '*frpc'
  tar zxvf "${TMPDIR}${dl_filename}" -C "$BIN_DIR" --strip-components 1 '*frps'
}

pm2config() {
  local name="$1"
  local bin_file="$BIN_DIR/$name"
  local config_file="$MY_CONFIG_DIR/$name.ini"
  local file_path="$MY_CONFIG_DIR/$name.config.js"

  if [[ $# -eq 0 ]]; then
    ls -l "$MY_CONFIG_DIR" | grep --color '[^ ]\+.config.js'
    exit 0
  fi

  if [[ $name != "frpc" && $name != "frps" ]]; then
    log only support frpc or frps
    exit 1
  fi

  cat > "$file_path" << EOF
module.exports = {
  apps: [
    {
      name: '$name',
      script: '$bin_file',
      args: '-c $config_file',
      log_date_format: 'YYMMDD HH:mm:ss Z'
    }
  ]
}
EOF

  echo "RUN pm2 start $file_path"
}

install_service() {
  local name="$1"
  local bin_file="$BIN_DIR/$name"
  local config_file="$MY_CONFIG_DIR/$name.ini"
  local log_file="$MY_CACHE_DIR/$name.log"

  if [[ $name != "frpc" || $name != "frps" ]]; then
    log only support frpc or frps
    exit 1
  fi

  if [[ $OS == 'Darwin' ]]; then
    echo "Not Implement"

  else

    if command_exist systemctl; then
      local file_path="/usr/lib/systemd/system/$name.service"
      sudo cat > "$file_path" << EOF
[Unit]
Description=frp

[Service]
Type=simple
ExecStart=$bin_file -c $config_file -L $log_file

[Install]
WantedBy=multi-user.target
EOF

    else
      local file_path="/etc/init.d/$name"

      # https://gist.github.com/blalor/c325d500818361e28daf
      cat > "$file_path" << EOF
#!/bin/bash
#
# frpd    Start up the frp
#
# chkconfig: 2345 20 80
# description: A fast reverse proxy to help you expose a local server behind a NAT or firewall to the internet.

# Source function library.
. /etc/init.d/functions

prog=$name
exec=$bin_file
lockfile=/var/lock/subsys/\$prog
pidfile=/var/run/\$prog.pid
logfile=$log_file
conffile=$config_file

start() {
  echo -n "Starting \$prog: "
  daemon --pidfile=\$pidfile " { \$exec -c \$conffile -L \$logfile & } ; echo \\\$! >| \$pidfile "
  retval=\$?
  echo
  [ \$retval -eq 0 ] && touch \$lockfile
  return \$retval
}

stop() {
  echo -n "Shutting down \$prog: "
  killproc -p \$pidfile \$exec
  retval=\$?
  echo
  [ \$retval -eq 0 ] && rm -f \$lockfile
  return \$retval
}

case "\$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  status)
    status -p \$pidfile -l \$prog \$exec
    ;;
  restart|reload)
    stop
    start
    ;;
  *)
    echo "Usage: \$prog {start|stop|status|reload|restart"
    exit 1
    ;;
esac

exit \$?
EOF

      chmod +x "$file_path"

      if command_exist update-rc.d; then
        update-rc.d $name enable
      else
        chkconfig --add $name
      fi

    fi

  fi
}

run_cmd "$@"

