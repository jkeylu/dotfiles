#!/usr/bin/env bash

source "$HOME/.dotfiles/util.sh"

init_work_dir frp

help() {
  cat << EOF
supported commands:
  install
  update
  install_service [frpc|frps]
EOF
}

dl_filename=""
download() {
  local repo="fatedier/frp"
  local tag=`gh_latest_tag $repo`
  local version="${tag#v}"

  if [[ `uname` == 'Darwin' ]]; then
    dl_filename="frp_${version}_darwin_amd64.tar.gz"
  elif [[ `uname` == 'Linux' ]]; then
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
  check_command frpc

  download

  tar zxvf "${TMPDIR}${dl_filename}" -C "$BIN_DIR" --strip-components 1 '*frpc'
  tar zxvf "${TMPDIR}${dl_filename}" -C "$BIN_DIR" --strip-components 1 '*frps'
  tar zxvf "${TMPDIR}${dl_filename}" -C "$MY_CONFIG_DIR" --strip-components 1 '*frp*.ini'
}

update() {
  if [[ -x "$BIN_DIR/frpc" ]]; then
    log "current frpc version: $($BIN_DIR/frpc --version)"
  fi
  if [[ -x "$BIN_DIR/frps" ]]; then
    log "current frps version: $($BIN_DIR/frps --version)"
  fi

  download

  tar zxvf "${TMPDIR}${dl_filename}" -C "$BIN_DIR" --strip-components 1 '*frpc'
  tar zxvf "${TMPDIR}${dl_filename}" -C "$BIN_DIR" --strip-components 1 '*frps'
}

pm2_config() {
  local name="$1"
  local bin_file="$BIN_DIR/$name"
  local config_file="$MY_CONFIG_DIR/$name.ini"

  check_pm2_config "$name"

  create_pm2_config "$name" "$bin_file" "-c $config_file"
}

install_service() {
  local name="$1"

  if [[ $name != "frpc" && $name != "frps" ]]; then
    log only support "frpc" or "frps"
    exit 1
  fi

  pm2_config "$name"
}

run_cmd "$@"
