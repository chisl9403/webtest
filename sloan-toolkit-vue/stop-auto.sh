#!/bin/bash
# 自动化停止脚本 - 无需确认

set -e

PROJECT_DIR="/Users/chishiliang/sw/test/sloan-toolkit-vue"
cd "$PROJECT_DIR"

echo "🛑 自动停止服务..."

# 强制停止所有相关进程
killall -9 node python3 Python 2>/dev/null || true
sleep 2

# 清理临时文件
rm -f backend.log flask.log server_output.log nohup.out 2>/dev/null || true
rm -f *.pid 2>/dev/null || true

# 验证
if ! lsof -ti:5002 > /dev/null && ! lsof -ti:3000 > /dev/null; then
    echo "✅ 所有服务已停止"
    echo "✅ 临时文件已清理"
else
    echo "⚠️  仍有进程在运行，请手动检查"
fi
