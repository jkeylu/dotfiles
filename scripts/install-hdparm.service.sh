#!/usr/bin/env bash

# Usage:
# wget -O- https://raw.githubusercontent.com/jkeylu/dotfiles/master/scripts/install-hdparam.service.sh | sudo bash

cat > /etc/systemd/system/hdparm.service << EOF
[Unit]
Description=hdparm service

[Service]
Type=oneshot
ExecStart=$(which hdparm) -S 241 -y /dev/sdx
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