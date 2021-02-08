#!/usr/bin/env bash

REPO="nadoo/glider"

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
  local cmd="glider"
  pre_check_command $cmd

  local cmd_path="$BIN_DIR/$cmd"
  local current_version=""
  if [[ -x "$cmd_path" ]]; then
    current_version="$($cmd_path --help 2>&1 | grep -o 'glider [0-9]\+\.[0-9]\+\.[0-9]\+')"
    if [[ -n $current_version ]]; then
      current_version=${current_version:7}
    fi
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
      basename="glider_${version}_linux_amd64"
    elif uname -m | grep -q '86'; then
      basename="glider_${version}_linux_386"
    elif uname -m | grep -q 'mips'; then
      basename="glider_${version}_linux_mipsle_hardfloat"
    fi
  fi

  if [[ -z $basename ]]; then
    log "Not supported system"
    exit 1
  fi

  local dl_filename="$basename.tar.gz"
  gh_download $REPO $tag $dl_filename
  tar zxvf "$TMP_DIR/$dl_filename" -C $TMP_DIR

  local glider_config_dir="$CONFIG_DIR/glider"
  mkdir -p "$glider_config_dir"

  local glider_svc=$(cat << EOF
[Unit]
Description=Glider Service
After=network.target iptables.service ip6tables.service

[Service]
Type=simple
User=nobody
Restart=always
LimitNOFILE=102400
Environment="GODEBUG=madvdontneed=1"

ExecStart=$cmd_path -config $glider_config_dir/glider.conf

# NOTE:
# work with systemd v229 or later, so glider can listen on port below 1024 with none-root user
# CAP_NET_ADMIN: ipset
# CAP_NET_BIND_SERVICE: bind ports under 1024
# CAP_NET_RAW: bind raw socket and broadcasting (used by dhcpd)
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF
)

  cp "$TMP_DIR/$basename/glider" "$BIN_DIR"
  cp -f -R $TMP_DIR/$basename/config/* "$glider_config_dir"

  if [[ ! -s "$SVC_DIR/glider.service" ]] || ! grep -q "$BIN_DIR/glider" "$SVC_DIR/glider.service"; then
    echo "$glider_svc" | sudo tee "$SVC_DIR/glider.service"
  fi

  rm -rf $TMP_DIR
}

install "$@"
