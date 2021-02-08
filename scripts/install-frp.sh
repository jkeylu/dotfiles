#!/usr/bin/env bash

REPO="fatedier/frp"

BIN_DIR="$HOME/.bin"
CONFIG_DIR="$HOME/.config"
SVC_DIR="/etc/systemd/system"
TMP_DIR="$(mktemp -d -p ${TMP_DIR:-/tmp})"

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m"

log() { echo -e "  ${GREEN}○${NC} $@"; }
command_exist() { command -v "$1" &> /dev/null; }

select_installation_path() {
  while true; do
    echo "Select the installation path:"
    echo -e "${YELLOW}1${NC}. $HOME/.bin"
    echo -e "${YELLOW}2${NC}. /usr/local/bin"
    echo -e "${YELLOW}3${NC}. /usr/bin"
    echo ""
    echo -e -n "Selection [${YELLOW}1${NC}/2/3]: "
    read -r input

    case $input in
      1) break;;
      2)
        BIN_DIR="/usr/local/bin"
        CONFIG_DIR="/usr/local/etc"
        break;;
      3)
        BIN_DIR="/usr/bin"
        CONFIG_DIR="/etc"
        break;;
      *)
        if [[ -z $input ]]; then
          break
        fi
        ;;
    esac
  done

  [[ -d $BIN_DIR ]] || mkdir -p "$BIN_DIR"
  [[ -d $CONFIG_DIR ]] || mkdir -p "$CONFIG_DIR"

  echo ""
}
select_installation_path

pre_check_command() {
  local cmd="$1"
  if ! command_exist "$cmd"; then
    return
  fi

  local existing_cmd_path=`which "$cmd"`
  if [[ "$existing_cmd_path" == "$BIN_DIR/$cmd" ]]; then
    return
  fi

  echo -e "command already exist: ${GREEN}${existing_cmd_path}${NC}"
  echo -n -e "Continue? [Yes/${YELLOW}No${NC}] "
  read -r input

  case $input in
    y|Y|yes|Yes) return;;
    *) exit 0;;
  esac
}

# gh_latest_tag "username/project_name"
gh_latest_tag() {
  local repo="$1"
  local tag="$(curl -is https://github.com/${repo}/releases/latest | sed -n 's|^Location:.*/tag/\(.*\)$|\1|p' | tr -d '\r\n')"
  if [[ -z $tag ]]; then
    tag="$(curl -s https://github.com/${repo}/releases | grep -o -m 1 'tag/[^"]\+' | sed -n 's|tag/\(.*\)$|\1|p')"
  fi
  echo "$tag"
}

# gh_download "username/project_name" "$version" "$filename"
gh_download() {
  local repo="$1"
  local version="$2"
  local filename="$3"

  local url="https://github.com/${repo}/releases/download/${version}/${filename}"
  local download_path="${TMP_DIR}/${filename}"

  log downloading $url
  curl -L --output "$download_path" "$url"
}

install() {
  local install_frpc="0"
  local install_frps="0"
  while (($#)); do
    case "$1" in
      --frpc) install_frpc="1";;
      --frps) install_frps="1";;
    esac
  done

  if [[ $install_frpc != "1" && $install_frps != "1" ]]; then
    while true; do
      echo "Select the installation file:"
      echo -e "${YELLOW}1${NC}. frpc"
      echo -e "${YELLOW}2${NC}. frps"
      echo -e "${YELLOW}3${NC}. frpc frps"
      echo ""
      read -r -p "Selection [1/2/3]: " input

      case $input in
        1)
          install_frpc="1"
          break;;
        2)
          install_frps="1"
          break;;
        3)
          install_frpc="1"
          install_frps="1"
          break;;
      esac
    done

    echo ""
  fi

  local cmd="frpc"
  if [[ $install_frpc != "1" ]]; then
    cmd="frps"
  fi
  pre_check_command $cmd

  local cmd_path="$BIN_DIR/$cmd"
  local current_version=""
  if [[ -x "$cmd_path" ]]; then
    current_version="$($cmd_path --version)"
    log "current $cmd version: $current_version"
  fi

  local tag=`gh_latest_tag $REPO`
  local version="${tag#v}"
  if [[ $version == $current_version ]]; then
    log "current version $current_version is latest version"
    exit 0
  fi
  log "latest version: $version"

  local basename=""
  if [[ `uname` == 'Linux' ]]; then
    if uname -m | grep -q '64'; then
      basename="frp_${version}_linux_amd64"
    elif uname -m | grep -q '86'; then
      basename="frp_${version}_linux_386"
    elif uname -m | grep -q 'mips'; then
      basename="frp_${version}_linux_mipsle"
    fi
  fi

  if [[ -z $basename ]]; then
    log "Not supported system"
    exit 1
  fi

  local dl_filename="$basename.tar.gz"
  gh_download $REPO $tag $dl_filename
  tar zxvf "$TMP_DIR/$dl_filename" -C $TMP_DIR

  local frp_config_dir="$CONFIG_DIR/frp"
  mkdir -p "$frp_config_dir"

  local frpc_svc=$(cat << EOF
[Unit]
Description=Frp Client Service
After=network.target

[Service]
Type=simple
User=nobody
Restart=on-failure
RestartSec=5s
ExecStart=$BIN_DIR/frpc -c $frp_config_dir/frpc.ini
ExecReload=$BIN_DIR/frpc reload -c $frp_config_dir/frpc.ini

[Install]
WantedBy=multi-user.target
EOF
)

  local frps_svc=$(cat << EOF
[Unit]
Description=Frp Server Service
After=network.target

[Service]
Type=simple
User=nobody
Restart=on-failure
RestartSec=5s
ExecStart=$BIN_DIR/frps -c $frp_config_dir/frps.ini

[Install]
WantedBy=multi-user.target
EOF
)

  if [[ $install_frpc == "1" ]]; then
    cp "$TMP_DIR/$basename/frpc" "$BIN_DIR"
    cp "$TMP_DIR/$basename/frpc_full.ini" "$frp_config_dir"
    [[ ! -s "$frp_config_dir/frpc.ini" ]] && cp "$TMP_DIR/$basename/frpc.ini" "$frp_config_dir"

    if [[ ! -s "$SVC_DIR/frpc.service" ]] || ! grep -q "$BIN_DIR/frpc" "$SVC_DIR/frpc.service"; then
      echo "$frpc_svc" | sudo tee "$SVC_DIR/frpc.service"
    fi
  fi

  if [[ $install_frps == "1" ]]; then
    cp "$TMP_DIR/$basename/frps" "$BIN_DIR"
    cp "$TMP_DIR/$basename/frps_full.ini" "$frp_config_dir"
    [[ ! -s "$frp_config_dir/frps.ini" ]] && cp "$TMP_DIR/$basename/frps.ini" "$frp_config_dir"

    if [[ ! -s "$SVC_DIR/frps.service" ]] || ! grep -q "$BIN_DIR/frps" "$SVC_DIR/frps.service"; then
      echo "$frps_svc" | sudo tee "$SVC_DIR/frps.service"
    fi
  fi

  rm -rf $TMP_DIR
}

install "$@"
