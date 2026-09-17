#!/usr/bin/env sh
# 重新注册 filesystem MCP server。
# 用途：docker compose down -v 删掉 db_data 卷之后，注册表会清空，跑这个恢复。
set -eu
cd "$(dirname "$0")/.."

# 容器内路径 = 挂载点 + 本仓库相对于挂载源的路径。
CFG=/host/build-tunnel/mcp/filesystem.json

docker compose exec -T mcpjungle sh -c "test -f $CFG" || {
  echo "错误：容器内看不到 $CFG" >&2
  echo "请检查 docker-compose.yaml 里 mcpjungle 的 volumes 挂载路径" >&2
  exit 1
}

# /mcpjungle 是容器根目录下的二进制，不在 PATH 里，必须写绝对路径。
# --force：同名 server 已存在时先注销再注册，所以这个脚本可以反复跑。
docker compose exec -T mcpjungle /mcpjungle register -c "$CFG" --force

echo
echo "当前已注册的 server："
docker compose exec -T mcpjungle /mcpjungle list servers
