---
name: cloudflare-mcp-tunnel
description: Use when exposing a local folder to web ChatGPT through Cloudflare Tunnel + mcpjungle, or when fixing one — triggers include adding a custom MCP connector, provisioning a dpdns.org domain, configuring Cloudflare Access Managed OAuth, and symptoms like Cloudflare error 1033, SSL handshake failure, or a connector that discovers no tools.
---

# Cloudflare MCP Tunnel

把本机文件夹通过 MCP 暴露给网页版 ChatGPT，全程不开公网入站端口。
本仓库 `docs/01`–`06` 是逐步教程（含截图与字段表）；**本 skill 负责编排、确认与交接**，不重复教程细节。

## 铁律

**先确认，再动手。** 这套流程会碰到用户的域名、Cloudflare 账号、ChatGPT 账号和本地文件，
多步有副作用且难以回滚。未经确认不要开始配置。

## 动手前必须问清（缺一不可）

| # | 问什么 | 为什么必须问 |
|---|---|---|
| 1 | **项目从哪来？** 当前目录已有仓库，还是要 clone 到新位置？有没有已存在的同名容器/隧道在跑？ | 决定后续所有相对路径；不确认就动手容易改错副本，或覆盖掉已跑着的实例 |
| 2 | **暴露哪个目录？读还是写？** | `:rw` 意味着 ChatGPT 能**改写和删除该目录下任何文件**。默认建议先 `:ro` 跑通 |
| 3 | **浏览器操作走哪套？** 见下节探测 | 决定你能自己点面板，还是全程要人 |

## 首次汇报的固定格式

动手前向用户汇报时，**必须逐项给出下面四行，一行都不能省**：

```
1. 项目来源：<用的是当前仓库 / 需要先 clone 到 ___ / 检测到已有实例在跑：___>
2. 暴露目标：<宿主机目录>  <:ro 或 :rw>
3. 浏览器方案：computer-use <可用 | 不可用>，最终采用 <computer-use | chrome-devtools MCP | Playwright>
```

第 3 行是硬性的：**即使你已经发现某个方案当场就能用，也必须先写出 computer-use 的探测结果**，
再写最终采用哪套。用户需要知道你在两套方案之间做过判断，而不是碰巧摸到一个能用的。

其余细节等做到那一步再问，别一次性抛十几个问题。

## 浏览器能力探测（按顺序试，不要跳）

```
1. computer-use 可用吗？
   ├─ 可用   → 用它
   └─ 不可用 → 2
2. 用户已有 Chrome 的调试端口开着吗？（9222 / 9223）
   ├─ 开着   → chrome-devtools MCP 接上去
   └─ 没开   → 3
3. 问用户：能否带 --remote-debugging-port 重启 Chrome？
   ├─ 同意   → 重启后走 chrome-devtools MCP（复用他现有登录态）
   └─ 不同意 → Playwright 独立 profile（等于从零登录，密码和验证码都得用户输）
```

**不要假设 `computer-use` 存在。** 它需要 Claude 订阅 + 服务端灰度开关，
走第三方端点代理（cc-switch 之类）时内置的那个永不注册。探测不到就走下一步，
并明确告诉用户你最终换用了哪套。

**优先复用用户已登录的真实 Chrome**：Cloudflare / ChatGPT 面板都要登录态，
独立 profile 等于重新登录还要过风控。

## 阶段

照 `docs/` 走，**每阶段结束停下来汇报再继续**：

| 阶段 | 文档 | 谁做 |
|---|---|---|
| 1 申请域名 | `docs/02-DigitalPlat获取域名.md` | **用户**（验证码 + 人机校验） |
| 2 托管到 Cloudflare + 建隧道 | `docs/03-Cloudflare绑定域名与创建隧道.md` | Agent 点面板；登录/2FA 由用户 |
| 3 compose + 注册 MCP | `docs/04-Docker-Tunnel-MCP.md` | Agent |
| 4 Public Hostname + ChatGPT 连接器 | `docs/05-ChatGPT自定义插件.md` | Agent 点面板；OAuth 授权由用户 |
| 5 Cloudflare Access + OAuth | `docs/06-OAuth 认证.md` | Agent 点面板；策略邮箱由用户确认 |

## 必须停下来交给用户的事

**不要尝试代劳，也不要假装能自动化：**

- 任何**密码、2FA、邮箱验证码、One-time PIN**
- **Cloudflare 登录页的 Turnstile 人机验证** —— 自动化点不过去
- **DigitalPlat 注册页**的人机校验与最终提交
- **ChatGPT 连接器的 OAuth 授权页**（点 Allow、输邮箱验证码）
- **同意重启 Chrome**（会关掉他当前所有标签页）
- **开通 Cloudflare Zero Trust Free Plan 时的绑卡**（visa / PayPal / 万事达）
- 在他账号里**新建 zone、Access 应用**等有副作用的操作

到了这些步骤，**说清楚要他做什么、在哪一屏，然后等**。
不要绕过，更不要让用户把密码或隧道 token 贴给你。

## 已知陷阱

| 陷阱 | 后果 |
|---|---|
| `scripts/register.sh` 用**容器内路径**找 `filesystem.json`（`/host/<repo>/mcp/...`） | 挂载源一改这个路径当场失效。挂载源指向别处时，需额外把仓库挂进容器（如 `/repo:ro`）并同步改脚本 |
| `docker compose up -d` 对未变更的容器是 **no-op** | 改完配置以为重启了其实没有。要重启用 `docker compose restart <服务>` |
| 加 Cloudflare Access 后 **`/health` 也返回 401** | 不能再拿它当隧道存活探针；改用 `docker compose logs cloudflared \| grep Registered` |
| 隧道 token 出现在日志或对话里 | 不要把 `.env` 内容、也不要把它解析出来的结果打印出来 |
| 代理软件（Clash 等）的 fake-IP 模式劫持 `argotunnel.com` | 隧道时好时坏或报 1033。退出代理后**必须重启 cloudflared** 才会重新解析边缘地址 |
| 上下文里的环境声明可能是**陈旧快照** | 例如「Is a git repository: false」可能是会话开始前的状态。动手前用 `git rev-parse --is-inside-work-tree` 自己复核，别照抄 |

## 完成判据

- `docker compose ps` 三个 Up，db healthy
- `docker compose logs cloudflared | grep Registered` 有 4 条
- ChatGPT 连接器能列出 `filesystem__*` 工具
- 加了 Access 后：`curl -si https://<域名>/mcp` 返回 **401** 且带 `WWW-Authenticate`
