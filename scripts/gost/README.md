# 家宽 gost 代理部署教程（独立文档）

> 本文档与启动脚本独立于签到项目核心代码。  
> 不修改 `checkin.py` / workflow 主逻辑也能在本地使用；GitHub Actions 若要用家宽代理，只需按文末自行加 1～2 个 Secret 与环境变量。

## 目标架构

```text
GitHub Actions / 本地脚本
  → http://用户:密码@域名:外网端口
  → 路由器端口映射（如 H3C ER3200G3-X）
  → 内网 gost :7890
  → anyrouter 等站点（出口 IP = 家宽公网 IP）
```

解决 GitHub Actions 共享出口 IP 过脏、易被 WAF 拦截的问题。

---

## 0. 前置条件

- 宽带有**真公网 IP**（非运营商大内网 / CGNAT）
- 一台常开机设备（Windows / Linux / NAS）跑 gost
- 一个域名（动态 IP 需 DDNS）
- 路由器支持端口映射 / 虚拟服务器

---

## 1. 生成密码（当 key 用）

gost 标准 HTTP 代理使用 **用户名 + 密码**。  
把密码做成超长随机串即可当作 key。

```bash
# Linux / macOS / Git Bash
openssl rand -hex 32
```

```powershell
# Windows PowerShell
-join ((48..57 + 97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
```

建议：

- 用户名：`checkin`（可改）
- 密码：上面生成的长串

---

## 2. 安装并启动 gost（推荐：Alpine Docker）

项目：https://github.com/go-gost/gost  
Releases：https://github.com/go-gost/gost/releases

### Alpine Docker（推荐，轻量）

适合 NAS / 小主机 / 旁路由上的 Docker，镜像基于 Alpine，体积极小。  
**宿主机不要挂全局 VPN**，否则出口会变成 VPN IP（你之前 16.40 就是这个问题）。

本目录已提供：

| 文件 | 说明 |
|------|------|
| `Dockerfile` | Alpine + gost |
| `docker-compose.yml` | 一键编排（默认 `network_mode: host`） |
| `docker-entrypoint.sh` | 启动入口 |
| `.env.example` | 账号密码 |
| `check-exit-ip.sh` | 对比直连/代理出口 IP |

```bash
cd scripts/gost
cp .env.example .env
# 编辑 .env：GOST_USER / GOST_PASS / GOST_PORT

chmod +x docker-entrypoint.sh check-exit-ip.sh
docker compose up -d --build

# 查看日志
docker compose logs -f

# 本机验收（应返回家宽拨号 IP，不是 VPN IP）
curl -x http://checkin:你的强密码@127.0.0.1:7890 https://api.ipify.org
# 或
./check-exit-ip.sh
```

**网络模式说明：**

- **Linux 宿主机（推荐）**：compose 默认 `network_mode: host`，端口直接监听宿主机，路由映射指宿主机 IP 即可。
- **Docker Desktop（Windows/macOS）**：host 网络不可用。编辑 `docker-compose.yml`：注释 `network_mode: host`，打开 `ports` 映射。

**一行 docker run（不依赖 compose）：**

```bash
docker build -t anyrouter-gost:alpine .

docker run -d --name anyrouter-gost --restart unless-stopped \
  --network host \
  -e GOST_USER=checkin \
  -e GOST_PASS='你的强密码' \
  -e GOST_PORT=7890 \
  anyrouter-gost:alpine
```

无 host 网络时：

```bash
docker run -d --name anyrouter-gost --restart unless-stopped \
  -p 7890:7890 \
  -e GOST_USER=checkin \
  -e GOST_PASS='你的强密码' \
  -e GOST_PORT=7890 \
  anyrouter-gost:alpine
```

容器起来后，H3C 端口映射：

| 项 | 值 |
|----|-----|
| 外网端口 | `27898`（示例） |
| 内网 IP | **Docker 宿主机**局域网 IP（如 `192.168.16.50`） |
| 内网端口 | `7890` |
| 协议 | TCP |

> 映射目标是跑 Docker 的那台机器，不是容器虚拟 IP。

### Windows 原生（可选，较重）

1. 下载 Windows amd64 包，解压得到 `gost.exe`
2. 将本目录 `start-gost.cmd` 与 `gost.exe` 放同一文件夹
3. 编辑 `start-gost.cmd` 中的 `GOST_USER` / `GOST_PASS` / `GOST_PORT`
4. 双击运行；需要开机自启可用「任务计划程序」

手动启动：

```bat
gost.exe -L "http://checkin:你的强密码@:7890"
```

局域网测试（IP 换成代理机）：

```bat
curl -x http://checkin:你的强密码@192.168.1.100:7890 https://api.ipify.org
```

应返回**你家公网 IP**。

### Linux

```bash
# 版本号以 Releases 为准
curl -L -o gost.tar.gz \
  https://github.com/go-gost/gost/releases/download/v3.0.0-rc10/gost_3.0.0-rc10_linux_amd64.tar.gz
tar -xzf gost.tar.gz
sudo mv gost /usr/local/bin/
sudo chmod +x /usr/local/bin/gost

export GOST_USER=checkin
export GOST_PASS='你的强密码'
export GOST_PORT=7890
./start-gost.sh
```

开机自启见同目录 `gost.service`。

---

## 3. 路由器端口映射（H3C ER3200G3-X 示例）

菜单大致在：**防火墙 / 安全 / NAT → 虚拟服务器 / 端口映射**

| 项 | 建议值 |
|----|--------|
| 外部端口 | `27890`（高位端口，勿直接暴露 7890） |
| 协议 | TCP |
| 内部 IP | 跑 gost 的机器，如 `192.168.1.100` |
| 内部端口 | `7890` |
| WAN | 有公网 IP 的那条线路 |

建议：

1. 给代理机做 **IP-MAC 绑定**，避免 DHCP 换 IP
2. 域名 `proxy.example.com` A 记录指向公网 IP（动态 IP 开 DDNS）
3. 多 WAN 时映射做在实际上网的那条 WAN

其他品牌路由同理：只要能做「公网端口 → 内网 IP:端口」即可。

---

## 4. 外网验收（手机 4G，勿用家里 WiFi）

```bash
curl -x http://checkin:你的强密码@proxy.example.com:27890 https://api.ipify.org
```

返回家宽公网 IP 即成功。

---

## 5. 对接 anyrouter-check-in（不改核心代码）

项目本身已支持环境变量：

```bash
CHECKIN_PROXY_URL=http://用户:密码@主机:端口
PROVIDERS={"anyrouter":{"use_proxy":true},"agentrouter":{"use_proxy":true}}
```

> **重要：** 内置 provider 默认 `use_proxy=false`。  
> 只配 `CHECKIN_PROXY_URL` 而不在 `PROVIDERS` 里打开 `use_proxy`，请求**不会**走代理。

### 5.1 本地运行

在项目根目录 `.env` 中增加（JSON 保持单行）：

```bash
CHECKIN_PROXY_URL=http://checkin:你的强密码@proxy.example.com:27890
PROVIDERS={"anyrouter":{"use_proxy":true},"agentrouter":{"use_proxy":true}}
```

然后：

```bash
uv run checkin.py
# 或
./bin/checkin.sh
```

### 5.2 GitHub Actions

在仓库 **Settings → Environments → production → Environment secrets** 添加：

| Name | Value |
|------|--------|
| `CHECKIN_PROXY_URL` | `http://checkin:你的强密码@proxy.example.com:27890` |
| `PROVIDERS` | `{"anyrouter":{"use_proxy":true},"agentrouter":{"use_proxy":true}}` |

当前上游 workflow 默认只注入 `PROXY_SUBSCRIPTION_URL`（mihomo 订阅）。  
若要用**家宽域名代理**，需要在 workflow「执行签到」步骤的 `env` 里自行增加一行（fork 后改自己的仓库即可）：

```yaml
CHECKIN_PROXY_URL: ${{ secrets.CHECKIN_PROXY_URL }}
```

参考片段见同目录 [`github-actions-snippet.yml`](./github-actions-snippet.yml)。

设置了自建 `CHECKIN_PROXY_URL` 后，一般**不必**再配 `PROXY_SUBSCRIPTION_URL`。

---

## 6. 安全清单

- [x] 必须用户名 + 强密码，禁止匿名代理
- [x] 外网使用高位端口
- [x] 代理密码与路由管理员密码分开
- [x] 只映射代理端口，管理口不对公网开放
- [x] 代理机固定内网 IP

---

## 7. 故障排查

| 现象 | 处理 |
|------|------|
| 局域网 curl 失败 | gost 未启动 / 密码错 / 本机防火墙拦截 7890 |
| 局域网通、外网不通 | 无真公网 IP / 映射未做 / 映射错 WAN / 运营商拦入站 |
| 签到仍被 WAF 拦 | 未设 `PROVIDERS.use_proxy=true`，仍在用 GitHub 脏 IP |
| Actions 日志无 proxy | workflow 未传入 `CHECKIN_PROXY_URL` Secret |
| 过几天突然不通 | 代理机 DHCP 变 IP，检查 IP-MAC 绑定 |

---

## 本目录文件

| 文件 | 说明 |
|------|------|
| `README.md` | 本教程 |
| `start-gost.cmd` | Windows 启动脚本 |
| `start-gost.sh` | Linux / macOS 启动脚本 |
| `gost.service` | systemd 开机自启示例 |
| `github-actions-snippet.yml` | Actions 注入家宽代理的参考片段 |

## 一句话

**gost 在路由后面提供 HTTP 代理；路由器只做端口透传；签到通过 `CHECKIN_PROXY_URL` + `use_proxy:true` 走家宽出口。**
