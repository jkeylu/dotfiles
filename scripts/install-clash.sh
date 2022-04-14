#!/usr/bin/env bash

REPO="Dreamacro/clash"

# {{{

BIN_DIR="$HOME/.bin"
CONFIG_DIR="$HOME/.config"
SVC_DIR="/etc/systemd/system"
TMP_DIR="$(mktemp -d -p ${TMP_DIR:-/tmp})"
GITHUB_HOST="hub.fastgit.org"
USER_AGENT="User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Safari/537.36"

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m"

log() { echo -e "  ${GREEN}○${NC} $@"; }
command_exist() { command -v "$1" &> /dev/null; }

# select_installation_path {{{
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
# }}}

# select_github_mirror {{{
select_github_mirror() {
  while true; do
    echo "Select Github mirror:"
    echo -e "${YELLOW}1${NC}. hub.fastgit.org"
    echo -e "${YELLOW}2${NC}. github.com.cnpmjs.org"
    echo -e "${YELLOW}3${NC}. github.com"
    echo ""
    echo -e -n "Selection [${YELLOW}1${NC}/2/3]: "
    read -r input

    case $input in
      1) break;;
      2)
        GITHUB_HOST="github.com.cnpmjs.org"
        break;;
      3)
        GITHUB_HOST="github.com"
        break;;
      *)
        if [[ -z $input ]]; then
          break
        fi
        ;;
    esac
  done

  echo ""
}
# }}}

# pre_check_command "command" {{{
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
# }}}

# gh_latest_tag "username/project_name" {{{
gh_latest_tag() {
  local repo="$1"
  local tag="$(curl -is -H '$USER_AGENT' https://${GITHUB_HOST}/${repo}/releases/latest | sed -n 's|^[Ll]ocation:.*/tag/\(.*\)$|\1|p' | tr -d '\r\n')"
  if [[ -z $tag ]]; then
    tag="$(curl -s -H '$USER_AGENT' https://${GITHUB_HOST}/${repo}/releases | grep -o -m 1 'tag/[^"]\+' | sed -n 's|tag/\(.*\)$|\1|p')"
  fi
  echo "$tag"
}
# }}}

# gh_download "username/project_name" "$version" "$filename" {{{
gh_download() {
  local repo="$1"
  local version="$2"
  local filename="$3"

  local url="https://${GITHUB_HOST}/${repo}/releases/download/${version}/${filename}"
  local download_path="${TMP_DIR}/${filename}"

  log downloading $url
  curl -L -H '$USER_AGENT' --output "$download_path" "$url"
}
# }}}

# }}}

select_installation_path
select_github_mirror

cmd="clash"
cmd_path="$BIN_DIR/$cmd"
cmd_config_dir="$CONFIG_DIR/$cmd"
cmd_svc_file_path="${SVC_DIR}/${cmd}.service"
cmd_local_version=""
cmd_remote_tag=""
cmd_remote_version=""
cmd_dl_filename=""

# get_cmd_local_version {{{
get_cmd_local_version() {
  local version=""
  if [[ -x "$cmd_path" ]]; then
    version="$($cmd_path -v | grep -i -o "$cmd v[0-9]\+\.[0-9]\+\.[0-9]\+")"
    if [[ -n $version ]]; then
      cmd_local_version=${version:7}
    fi
    log "Local $cmd version: $cmd_local_version"
  fi
}
# }}}

# get_cmd_remote_version {{{
get_cmd_remote_version() {
  cmd_remote_tag=`gh_latest_tag $REPO`
  cmd_remote_version="${cmd_remote_tag#v}"
  if [[ -z $cmd_remote_version ]]; then
    log "Fail to get remote version"
    exit 1
  fi
}
# }}}

# get_cmd_dl_filename {{{
get_cmd_dl_filename() {
  local version="$1"
  local basename=""
  if [[ `uname` == 'Linux' ]]; then
    if uname -m | grep -q '64'; then
      basename="${cmd}-linux-amd64-v${version}"
    elif uname -m | grep -q '86'; then
      basename="${cmd}-linux-386-v${version}"
    elif uname -m | grep -q 'mips'; then
      basename="${cmd}-linux-mipsle-hardfloat-v${version}"
    fi
  fi

  if [[ -z $basename ]]; then
    log "Not supported system"
    exit 1
  fi

  log :${basename}:

  cmd_dl_filename="$basename.gz"
}
# }}}

# save_cmd_svc_file {{{
save_cmd_svc_file() {
  local cmd_svc=$(cat << EOF
[Unit]
Description=${cmd} Service
After=network.target iptables.service ip6tables.service

[Service]
Type=simple
User=nobody
Restart=always
LimitNOFILE=102400

ExecStart=${cmd_path}

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

  if [[ ! -s $cmd_svc_file_path ]] || ! grep -q "$cmd_path" "$cmd_svc_file_path"; then
    echo "$cmd_svc" | sudo tee "$cmd_svc_file_path"
  fi
}
# }}}

# install {{{
install() {
  pre_check_command $cmd
  get_cmd_local_version
  get_cmd_remote_version

  if [[ $cmd_remote_version == $cmd_local_version ]]; then
    log "Current version $cmd_local_version is latest version"
    exit 0
  fi
  log "Latest version: $cmd_remote_version"

  get_cmd_dl_filename "$cmd_remote_version"

  gh_download $REPO $cmd_remote_tag $cmd_dl_filename
  gunzip -c "$TMP_DIR/$cmd_dl_filename" > "$cmd_path"
  chmod 755 "$cmd_path"

  save_cmd_svc_file

  rm -rf $TMP_DIR
}
# }}}

install "$@"

