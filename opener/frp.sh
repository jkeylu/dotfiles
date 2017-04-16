#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

init_work_dir frp

help() {
  cat << EOF
supported commands:
  install
  install service
  install server
  install server service
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
    if uname -i | grep --silent '64'; then
      dl_filename="frp_${version}_linux_amd64.tar.gz"
    elif uname -i | grep --silent '86'; then
      dl_filename="frp_${version}_linux_386.tar.gz"
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
  tar zxvf "${TMPDIR}${dl_filename}" -C "$I_CONFIG_DIR" --strip-components 1 '*frpc*.ini'
}

_install_service() {
  local name="$1"
  local bin_file="$BIN_DIR/$name"
  local config_file="$I_CONFIG_DIR/${name}.ini"

  if [[ $OS == 'Darwin' ]]; then
    echo "Not Implement"

  else

    if command_exist systemctl; then
      local file_path="/usr/lib/systemd/system/${name}.service"
      sudo cat > "$file_path" << EOF
[Unit]
Description=frp

[Service]
Type=forking
ExecStart=${bin_file} -c ${config_file}

[Install]
WantedBy=multi-user.target
EOF

    else
      local file_path="/etc/init.d/frpd"
      local bin_file="$BIN_DIR/${name}"
      local config_file="$I_CONFIG_DIR/${name}.ini"

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

prog=frpd
exec=$bin_file
lockfile=/var/lock/subsys/\$prog
pidfile=/var/run/\$prog.pid
logfile=/var/log/\$prog
conffile=$config_file

start() {
  echo -n "Starting \$prog: "
  daemon --pidfile=\$pidfile " { \$exec -c \$conffile &>> \$logfile & } ; echo \\\$! >| \$pidfile "
  retval=\$?
  echo
  [ \$retval -eq 0 ] && touch \$lockfile
  return \$retval
}

stop() {
  echo -n "Shutting down \$prog: "
  killproc -p \$pidfile \$exec -INT
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
    status -p $pidfile -l $prog $exec
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
        update-rc.d frpd enable
      else
        chkconfig --add frpd
      fi

    fi

  fi
}

install_service() {
  _install_service frpc
}

install_server() {
  download

  tar zxvf "${TMPDIR}${dl_filename}" -C "$BIN_DIR" --strip-components 1 '*frps'
  tar zxvf "${TMPDIR}${dl_filename}" -C "$I_CONFIG_DIR" --strip-components 1 '*frps*.ini'
}

install_server_service() {
  _install_service frps
}

cmd="$(join_by _ "$@")"
if [[ -n $cmd ]]; then
  "$cmd"
else
  help
fi

