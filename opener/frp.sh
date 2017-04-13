#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../util.sh"

init_work_dir frp

help() {
  cat << EOF
supported commands:
  install
  install server
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

