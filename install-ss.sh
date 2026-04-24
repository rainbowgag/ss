#!/usr/bin/env bash
set -e

DEFAULT_PORT=443
DEFAULT_NAME="landing-vps"
METHOD="chacha20-ietf-poly1305"
PASSWORD=$(openssl rand -base64 16)

echo "请输入节点名称（默认：${DEFAULT_NAME}）："
read -r NODE_NAME
NODE_NAME=${NODE_NAME:-$DEFAULT_NAME}

echo "请输入端口（默认：${DEFAULT_PORT}）："
read -r PORT
PORT=${PORT:-$DEFAULT_PORT}

if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
  echo "端口无效，请输入 1-65535 之间的数字"
  exit 1
fi

apt update
apt install -y shadowsocks-libev qrencode curl openssl python3

mkdir -p /etc/shadowsocks-libev

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

grep -q '^net.core.default_qdisc=fq' /etc/sysctl.conf || echo 'net.core.default_qdisc=fq' >> /etc/sysctl.conf
grep -q '^net.ipv4.tcp_congestion_control=bbr' /etc/sysctl.conf || echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf
sysctl -p >/dev/null

IP=$(curl -4 -s ifconfig.me || hostname -I | awk '{print $1}')

USERINFO_BASE64=$(echo -n "${METHOD}:${PASSWORD}" | base64 -w 0)
NODE_NAME_ENCODED=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''${NODE_NAME}'''))")

SS_LINK="ss://${USERINFO_BASE64}@${IP}:${PORT}#${NODE_NAME_ENCODED}"
CLASH_NODE="- {name: '${NODE_NAME}', type: ss, server: ${IP}, port: ${PORT}, cipher: ${METHOD}, password: '${PASSWORD}', udp: true}"

echo
echo "====== Shadowsocks 安装完成 ======"
echo "节点名称: ${NODE_NAME}"
echo "服务器 IP: ${IP}"
echo "端口: ${PORT}"
echo "密码: ${PASSWORD}"
echo "加密: ${METHOD}"
echo
echo "BBR 状态:"
sysctl net.ipv4.tcp_congestion_control
echo
echo "SS 链接:"
echo "${SS_LINK}"
echo
echo "Clash 单行节点:"
echo "${CLASH_NODE}"
echo
echo "二维码:"
qrencode -t ANSIUTF8 "${SS_LINK}"
echo
