#!/usr/bin/env bash
set -e

CONFIG="/etc/shadowsocks-libev/config.json"
NAME_FILE="/etc/shadowsocks-libev/node_name"

DEFAULT_PORT=443
DEFAULT_NAME="landing-vps"
METHOD="chacha20-ietf-poly1305"

enable_bbr() {
  grep -q '^net.core.default_qdisc=fq' /etc/sysctl.conf || echo 'net.core.default_qdisc=fq' >> /etc/sysctl.conf
  grep -q '^net.ipv4.tcp_congestion_control=bbr' /etc/sysctl.conf || echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf
  sysctl -p >/dev/null 2>&1 || true
}

get_ip() {
  curl -4 -s ifconfig.me || hostname -I | awk '{print $1}'
}

show_link() {
  if [ ! -f "$CONFIG" ]; then
    echo "未找到 SS 配置，请先运行安装。"
    exit 1
  fi

  IP=$(get_ip)
  PORT=$(grep '"server_port"' "$CONFIG" | grep -o '[0-9]\+')
  PASSWORD=$(grep '"password"' "$CONFIG" | cut -d '"' -f4)
  METHOD=$(grep '"method"' "$CONFIG" | cut -d '"' -f4)
  NODE_NAME=$(cat "$NAME_FILE" 2>/dev/null || echo "$DEFAULT_NAME")

  USERINFO_BASE64=$(echo -n "${METHOD}:${PASSWORD}" | base64 -w 0)
  NODE_NAME_ENCODED=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''${NODE_NAME}'''))")

  SS_LINK="ss://${USERINFO_BASE64}@${IP}:${PORT}#${NODE_NAME_ENCODED}"
  CLASH_NODE="- {name: '${NODE_NAME}', type: ss, server: ${IP}, port: ${PORT}, cipher: ${METHOD}, password: '${PASSWORD}', udp: true}"

  echo
  echo "====== 当前 SS 节点信息 ======"
  echo "节点名称: ${NODE_NAME}"
  echo "服务器 IP: ${IP}"
  echo "端口: ${PORT}"
  echo "密码: ${PASSWORD}"
  echo "加密: ${METHOD}"
  echo
  echo "SS 链接:"
  echo "${SS_LINK}"
  echo
  echo "Clash 单行节点:"
  echo "${CLASH_NODE}"
  echo
}

install_ss() {
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

  PASSWORD=$(openssl rand -base64 16)

  apt update
  apt install -y shadowsocks-libev qrencode curl openssl python3

  mkdir -p /etc/shadowsocks-libev

  cat > "$CONFIG" <<EOF
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

  echo "$NODE_NAME" > "$NAME_FILE"

  systemctl enable shadowsocks-libev
  systemctl restart shadowsocks-libev

  enable_bbr

  show_link

  echo "二维码:"
  SS_LINK=$(bash "$0" sslink | awk '/^ss:\/\// {print $0}')
  qrencode -t ANSIUTF8 "$SS_LINK"
  echo
}

delete_ss() {
  systemctl stop shadowsocks-libev 2>/dev/null || true
  systemctl disable shadowsocks-libev 2>/dev/null || true

  rm -f "$CONFIG"
  rm -f "$NAME_FILE"

  echo "SS 节点已删除。"
  echo "注意：软件包 shadowsocks-libev 未卸载，如需卸载请执行："
  echo "apt remove -y shadowsocks-libev"
}

case "$1" in
  sslink)
    show_link
    ;;
  delete|uninstall|remove)
    delete_ss
    ;;
  *)
    install_ss
    ;;
esac
