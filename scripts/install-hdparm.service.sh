#!/usr/bin/env bash

# Usage:
# sudo bash <(wget -O- https://raw.githubusercontent.com/jkeylu/dotfiles/master/scripts/install-hdparam.service.sh) install
# sudo ./.dotfiles/scripts/install-hdparam.service.sh install

install() {
  cat > /etc/systemd/system/hdparm.service << EOF
[Unit]
Description=hdparm service

[Service]
Type=oneshot
ExecStart=$(which hdparm) -S 241 -y /dev/sda
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

  if command -v vim &> /dev/null; then
    vim /etc/systemd/system/hdparm.service
  else
    vi /etc/systemd/system/hdparm.service
  fi

  systemctl enable hdparm
}

uninstall() {
  systemctl disable hdparm
  rm -f /etc/systemd/system/hdparm.service
}

case "$1" in
  install)
    install
    ;;
  uninstall)
    uninstall
    ;;
esac
