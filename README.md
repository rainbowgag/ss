# SS Landing VPS 一键脚本

适用于 Debian / Ubuntu VPS，一键安装 Shadowsocks-libev 落地节点，并自动开启 BBR 加速。

## 功能

- 一键安装 SS 落地节点
- 自定义节点名称
- 自定义端口
- 自动生成随机密码
- 自动输出 SS 链接
- 自动输出 Clash 单行节点格式
- 自动生成二维码
- 自动开启 BBR 加速
- 支持查看已创建节点
- 支持一键删除节点

---

## 一键安装

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/rainbowgag/ss/refs/heads/main/install-ss.sh)
```

安装过程中：

- 输入节点名称（可回车默认）
- 输入端口（可回车默认 443）

安装完成后自动输出：

- SS 链接
- Clash 节点
- 二维码

---

## 查看已创建节点

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/rainbowgag/ss/refs/heads/main/install-ss.sh) sslink
```

可重新显示：

- SS 链接
- Clash 单行节点
- 二维码

---

## 删除节点

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/rainbowgag/ss/refs/heads/main/install-ss.sh) delete
```

删除：

- Shadowsocks 配置
- 节点信息

---

## 开启 BBR 验证

```bash
sysctl net.ipv4.tcp_congestion_control
lsmod | grep bbr
```

如果显示：

```bash
net.ipv4.tcp_congestion_control = bbr
tcp_bbr
```

说明 BBR 已开启。

---

## Clash 节点示例

```yaml
- {name: 'ceshi', type: ss, server: 1.1.1.1, port: 2235, cipher: chacha20-ietf-poly1305, password: 'password', udp: true}
```

---

## 适用系统

- Debian 11 / 12
- Ubuntu 20.04 / 22.04

---

## 注意

如果 VPS 防火墙开启，请放行自定义端口。

默认使用：

- chacha20-ietf-poly1305
- TCP + UDP
- BBR

适合作为落地 VPS 使用。
