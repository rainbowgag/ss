#!/usr/bin/env bash
set -e

PORT=443
METHOD="chacha20-ietf-poly1305"
PASSWORD=$(openssl rand -base64 16)

apt update
apt install -y shadowsocks-libev qrencode curl openssl

cat > /etc/shadowsocks-libev/config.json <<EOF
{
  "server": "0.0.0.0",
  "server_port": ${PORT},
  "password": "${PASSWORD}",
  "timeout": 300,
  "method": "${METHOD}",
  "fast_open": false,
  "mode": "tcp_and_udp"
}
EOF

systemctl enable shadowsocks-libev
systemctl restart shadowsocks-libev

IP=$(curl -4 -s ifconfig.me || hostname -I | awk '{print $1}')
SS_BASE64=$(echo -n "${METHOD}:${PASSWORD}@${IP}:${PORT}" | base64 -w 0)
SS_LINK="ss://${SS_BASE64}#landing-vps"

echo
echo "====== Shadowsocks 安装完成 ======"
echo "服务器 IP: ${IP}"
echo "端口: ${PORT}"
echo "密码: ${PASSWORD}"
echo "加密: ${METHOD}"
echo
echo "SS 链接:"
echo "${SS_LINK}"
echo
echo "二维码:"
qrencode -t ANSIUTF8 "${SS_LINK}"
echo
