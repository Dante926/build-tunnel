# Docker-Tunnel-MCP

上一章拿到了以 Docker 为安装环境的 `docker run` 指令。这一章用 docker compose 统一管理 `cloudflared` 与 `mcpjungle`。

> **mcpjungle 是什么**：一个统一的 MCP 注册网关。它把多个上游 MCP server 收编成单个 HTTP 端点供外部服务调用，并托管 stdio 类型的 MCP server 子进程。

## 初始化目录与隧道

1. 创建一个文件夹（**如果不是以 git clone 该项目**，请按自己的风格命名，这里用 `tunnel/`），创建 `.env`：

```sh
TUNNEL_TOKEN = "<上一章得到的 TUNNEL_TOKEN>"
HOST_DIR = "" # 开放给 GPT 操作的根目录
```

2. 创建 `docker-compose.yaml`，先只放 cloudflared：

```yaml
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cf-tunnel
    restart: unless-stopped
    command: tunnel --no-autoupdate run --token ${TUNNEL_TOKEN}
```

3. 运行：

```sh
docker compose config   # 查看环境变量是否正常载入
docker compose up -d    # 启动容器
docker compose ps       # 查看当前 compose 对应容器
```

4. 验证隧道

回到 Cloudflare → **Networking** → **Tunnel** → 域名，隧道状态应为 **Healthy**，或查看日志：

```sh
docker logs <容器名或容器ID> --tail 50
```

看到 `Registered tunnel connection` 即表示 cloudflared 已与 Cloudflare 边缘建立连接。

## 补全 mcpjungle 与 db

`docker-compose.yaml` 更新为：

```yaml
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cf-tunnel
    restart: unless-stopped
    command: tunnel --no-autoupdate run --token ${TUNNEL_TOKEN}
    depends_on:
      - mcpjungle

  db:
    image: postgres:17
    container_name: mcpjungle-db
    environment:
      POSTGRES_USER: mcpjungle
      POSTGRES_PASSWORD: mcpjungle
      POSTGRES_DB: mcpjungle
    volumes:
      - db_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "PGPASSWORD=mcpjungle pg_isready -U mcpjungle"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  mcpjungle:
    image: ghcr.io/mcpjungle/mcpjungle:latest-stdio
    container_name: mcpjungle-server
    environment:
      DATABASE_URL: postgres://mcpjungle:mcpjungle@db:5432/mcpjungle
      SERVER_MODE: development
      MCP_SERVER_INIT_REQ_TIMEOUT_SEC: 30
    ports:
      - "127.0.0.1:8080:8080"
    volumes:
      - ${HOST_DIR:?}:/host:rw
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped

volumes:
  db_data:
```

运行 `docker compose up -d` 更新并启动容器。无报错后访问 <http://127.0.0.1:8080>
会看到 mcpjungle dashboard。

### 几点说明

| 配置                                       | 说明                                                                           |
| ------------------------------------------ | ------------------------------------------------------------------------------ |
| `ghcr.io/mcpjungle/mcpjungle:latest-stdio` | 必须是 `latest-stdio` 变体。它包含 node/npx，注册 npx 型 stdio server 才起得来 |
| `ports: "127.0.0.1:8080:8080"`             | 把容器 8080 映射到宿主机 8080，且**只绑本地回环**，公网访问不到                |
| `mcpjungle:8080`                           | 三个服务在同一 compose 网络里，服务名可直接当主机名用                          |
| `db_data`                                  | 命名卷，存 mcpjungle 的注册表。`docker compose down` 不删，加 `-v` 才会删     |
| `:rw`                                      | 挂载可写。ChatGPT 因此能改写、删除该目录下任何文件；只读用途改成 `:ro`         |
| `${HOST_DIR:?}:/host:rw`  | 冒号左边是宿主机路径，右边是容器内路径。该宿主机目录会成为 mcpjungle 可操作的根目录。 |

## 注册 filesystem MCP

1. 创建 `/tunnel/mcp/filesystem.json`：

```json
{
  "name": "filesystem",
  "transport": "stdio",
  "description": "dante926 project files read/write",
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-filesystem", "/host"],
  "session_mode": "stateless"
}
```

> `args` 里的 `/host` 是**容器内**路径，对应上面 compose 里 `volumes` 挂载的目标，
> 不是宿主机路径。

2. 在 `tunnel/` 目录下运行:

```sh
curl -X POST http://127.0.0.1:8080/api/v0/servers \
  -H 'Content-Type: application/json' \
  -d @mcp/filesystem.json
```

3. 验证注册:

```sh
curl -s http://127.0.0.1:8080/api/v0/servers
```

输出里能看到 `filesystem` 条目即为成功，也可以访问 <http://127.0.0.1:8080> 在 dashboard 中查看注册记录。

```json
[
  {
    "name": "filesystem",
    "transport": "stdio",
    "enabled": true,
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-filesystem", "/host"],
    "session_mode": "stateless"
  }
]
```

## 阅读顺序

1. [从零搭建](./01-从零搭建.md)
2. [DigitalPlat 获取域名](./02-DigitalPlat获取域名.md)
3. [Cloudflare 绑定域名与创建隧道](./03-Cloudflare绑定域名与创建隧道.md)
4. Docker-Tunnel-MCP
5. [ChatGPT 添加自定义插件](./05-ChatGPT自定义插件.md)
6. [Cloudflare OAuth 认证](./06-OAuth%20认证.md)
