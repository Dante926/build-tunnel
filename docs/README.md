# Local ChatGPT 搭建文档

把本机的一个文件夹通过 MCP 协议暴露给 Web 版 ChatGPT 读写。全程不开任何公网入站端口。

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
| 01 | [从零搭建](./01-从零搭建.md) | 总览、链路图、前置条件 |
| 02 | [获取域名](./02-获取域名.md) | DigitalPlat 免费申请 `.dpdns.org` |
| 03 | [绑定域名与创建隧道](./03-绑定域名与创建隧道.md) | NS 托管到 Cloudflare、建隧道拿 token |
| 04 | [Compose 与 MCP 注册](./04-Compose%20与%20MCP%20注册.md) | 三服务 compose、注册 filesystem server |
| 05 | [连接 ChatGPT](./05-连接%20ChatGPT.md) | Public Hostname、ChatGPT 连接器 |
| 06 | [OAuth 认证](./06-OAuth%20认证.md) | Cloudflare Access、Managed OAuth |

## 相关文件

| 路径 | 说明 |
| --- | --- |
| `../docker-compose.yaml` | 三个服务的编排 |
| `../mcp/filesystem.json` | filesystem server 注册配置 |
| `../.env.example` | 环境变量模板（真实 token 放 `.env`，不入库） |
| `./assets/` | 文档配图 |

## 约定

- 文中 `xxx.dpdns.org` 是占位符，替换成你自己的域名
- 隧道 token 属密钥，只放 `.env`，不要提交进 git
