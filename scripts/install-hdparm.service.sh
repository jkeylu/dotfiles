#!/usr/bin/env sh

# Usage:
# sudo sh -c "$(wget -O- https://raw.githubusercontent.com/jkeylu/dotfiles/master/scripts/install-hdparm.service.sh)"

GREEN="\033[0;32m"
NC="\033[0m"

cat > /etc/systemd/system/hdparm.service << EOF
[Unit]
Description=hdparm service

[Service]
Type=oneshot
# `Type=oneshot` support multiple ExecStart
# `-S 241` 30 minutes
# `-y` standby immediately
ExecStart=$(which hdparm) -S 241 -y /dev/sdx
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

echo "Edit hdparm.service: ${GREEN}vim /etc/systemd/system/hdparm.service${NC}"
echo "Enable hdparm.service: ${GREEN}systemctl enable hdparm${NC}"
