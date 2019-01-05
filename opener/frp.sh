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

  local current_version="$1"
  if [[ $version == $current_version ]]; then
    log "$version is latest version"
    exit 0
  fi

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

  tar zxvf "${TMPDIR}${dl_filename}" -C "$BIN_DIR" --strip-components 1
  mv $BIN_DIR/frp*.ini $MY_CONFIG_DIR
  rm -f $BIN_DIR/LICENSE
}

update() {
  local current_version
  if [[ -x "$BIN_DIR/frpc" ]]; then
    current_version="$($BIN_DIR/frpc --version)"
    log "current frp version: $current_version"
  fi

  download "$current_version"

  tar zxvf "${TMPDIR}${dl_filename}" -C "$BIN_DIR" --strip-components 1
  rm -f $BIN_DIR/frp*.ini $BIN_DIR/LICENSE
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
