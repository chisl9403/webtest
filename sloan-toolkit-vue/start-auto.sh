#!/bin/bash
# 自动化启动脚本 - 无需确认

set -e  # 遇到错误立即退出

PROJECT_DIR="/Users/chishiliang/sw/test/sloan-toolkit-vue"
cd "$PROJECT_DIR"

echo "🚀 自动启动服务..."

# 1. 清理旧进程（自动，无确认）
killall -9 node python3 Python 2>/dev/null || true
sleep 2

# 2. 启动后端
echo "📡 启动 Flask 后端..."
python3 server.py > /dev/null 2>&1 &
BACKEND_PID=$!
sleep 3

# 3. 启动前端
echo "🌐 启动 Vite 前端..."
npm run dev > /dev/null 2>&1 &
FRONTEND_PID=$!
sleep 3

# 4. 验证服务
if lsof -ti:5002 > /dev/null && lsof -ti:3000 > /dev/null; then
    echo "✅ 服务启动成功！"
    echo "   后端: http://localhost:5002 (PID: $BACKEND_PID)"
    echo "   前端: http://localhost:3000 (PID: $FRONTEND_PID)"
    echo ""
    echo "🌐 访问: http://localhost:3000"
else
    echo "❌ 服务启动失败，请检查日志"
    exit 1
fi
