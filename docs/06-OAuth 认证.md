# Cloudflare OAuth 认证

## OAuth

推荐阅读阮一峰老师的[《OAuth 2.0 的一个简单解释》](https://www.ruanyifeng.com/blog/2019/04/oauth_design.html)

## 建立 Access 应用

去 `one.dash.cloudflare.com`（Zero Trust 控制台，不是普通 dashboard）：

**Access controls** → **Applications** → **"Create new application"** → **"Self-hosted and private"** → **"Public DNS"** → **"Continue with Self-hosted and private"**

### Application details

1. **Destinations**

| 字段      | 值              |
| --------- | --------------- |
| Subdomain | `mcp`           |
| Domain    | `xxx.dpdns.org` |
| Path      | 空              |

2. **Access policies**: 点击 Create new policy

- 左侧 **Policy rules**：下拉框选择 `Emails`，邮箱填写注册 Cloudflare 的邮箱
- 右侧 **Policy details**：Policy name 填 `only-me`，Action 选 `Allow`
- **"Save policy"**

**Authentication**：默认

**Details:**

| 字段             | 值          |
| ---------------- | ----------- |
| Name             | `MCPJungle` |
| Session Duration | `24 hours`  |

### Additional settings

> `Additional` 和 `Applicantion details` 是同级 tab 记得滑动界面回至顶部

**App Launcher customization**

| 字段                             | 值        |
| -------------------------------- | --------- |
| Set App Launcher logo            | `Default` |
| Set domain for App Launcher tile | `Default` |

**OAuth**：打开

找到 **Add URI**，填入：

```
https://chatgpt.com/*
```

## 3. 重新建立 ChatGPT 连接器

1. ChatGPT → 设置 → 连接器（Connectors）→ 新建
2. **URL**：`https://mcp.xxx.dpdns.org/mcp`（不变）
3. **验证方式**：这次选 `OAuth`（ChatGPT 探测到 401 后通常会自动识别并弹出授权）
4. 保存后会自动弹出浏览器 → 走 Cloudflare Access 登录页
5. 登录用 `xxx@xxx.com`（就是 Access 策略里放行的那个邮箱）。team 如果只配了
   One-time PIN，会往这个邮箱发验证码

## 阅读顺序

1. [从零搭建](./01-从零搭建.md)
2. [DigitalPlat 获取域名](./02-DigitalPlat获取域名.md)
3. [Cloudflare 绑定域名与创建隧道](./03-Cloudflare绑定域名与创建隧道.md)
4. [Docker-Tunnel-MCP](./04-Docker-Tunnel-MCP.md)
5. [ChatGPT 添加自定义插件](./05-ChatGPT自定义插件.md)
6. Cloudflare OAuth 认证
