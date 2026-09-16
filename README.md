# Local ChatGPT 搭建文档

让 Web ChatGPT 读写本地文件。

## 链路

```
ChatGPT（云端）
  │  HTTPS  https://mcp.<域名>/mcp
  ▼
Cloudflare 边缘        证书终结 + 身份验证
  │  ingress 转发规则
  ▼
cloudflared            常驻出站连接
  │  compose 内网
  ▼
mcpjungle              把 stdio 的 MCP 包成 HTTP 端点
  │  stdio 子进程
  ▼
filesystem MCP server
  ▼
本机文件夹
```

## 文档

| # | 文档 | 内容 |
| --- | --- | --- |
| 01 | [从零搭建](./docs/01-从零搭建.md) | 总览、链路图、前置条件 |
| 02 | [DigitalPlat 获取域名](./docs/02-DigitalPlat获取域名.md) | 免费申请 `.dpdns.org` |
| 03 | [Cloudflare 绑定域名与创建隧道](./docs/03-Cloudflare绑定域名与创建隧道.md) | NS 托管到 Cloudflare、建隧道拿 token |
| 04 | [Docker-Tunnel-MCP](./docs/04-Docker-Tunnel-MCP.md) | 三服务 compose、注册 filesystem server |
| 05 | [ChatGPT 添加自定义插件](./docs/05-ChatGPT自定义插件.md) | Public Hostname、ChatGPT 连接器 |
| 06 | [Cloudflare OAuth 认证](./docs/06-OAuth%20认证.md) | Cloudflare Access、Managed OAuth |
| 07 | [故障排查](./docs/07-故障排查.md) | 症状 → 原因 → 修法 |

## 从零恢复

```sh
cp .env.example .env     # 填入 TUNNEL_TOKEN
docker compose up -d
docker compose ps        # db 需为 healthy
./scripts/register.sh    # 注册 filesystem MCP server
```

Cloudflare 侧的面板配置（隧道、Public Hostname、Access 应用）不在版本控制里，
需照 03、05、06 三篇手工重建。

## 相关文件

| 路径 | 说明 |
| --- | --- |
| `./docker-compose.yaml` | 三个服务的编排 |
| `./mcp/filesystem.json` | filesystem server 注册配置 |
| `./scripts/register.sh` | 重新注册 server（`down -v` 后恢复） |
| `./.env.example` | 环境变量模板，真实 token 放 `.env` |
| `./docs/assets/` | 文档配图 |

## 约定

- 文中 `xxx.dpdns.org` 是占位符，替换成你自己的域名
- 隧道 token 属密钥，只放 `.env`，不要提交进 git
- `mcpjungle` 以 `:rw` 挂载本机目录，ChatGPT 因此**可以改写、删除该目录下任何文件**
