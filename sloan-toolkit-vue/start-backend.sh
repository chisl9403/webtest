#!/bin/bash

# 启动后端服务器脚本

cd "$(dirname "$0")"

# 检查并杀死占用端口的进程
PORT=5002
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null ; then
    echo "端口 $PORT 已被占用，正在清理..."
    lsof -ti:$PORT | xargs kill -9 2>/dev/null
    sleep 1
fi

# 启动服务器
echo "启动 Flask 后端服务器 (端口 $PORT)..."
nohup python3 server.py > /tmp/flask_server.log 2>&1 &
SERVER_PID=$!

# 等待服务器启动
sleep 3

# 检查服务器是否成功启动
if curl -s http://127.0.0.1:$PORT/ > /dev/null 2>&1; then
    echo "✓ 服务器启动成功！"
    echo "  PID: $SERVER_PID"
    echo "  URL: http://127.0.0.1:$PORT/"
    echo "  日志: /tmp/flask_server.log"
    echo ""
    echo "已注册的插件:"
    curl -s http://127.0.0.1:$PORT/ | python3 -c "import sys,json; [print(f\"  - {p['name']}: {p['endpoint']}\") for p in json.load(sys.stdin).get('plugins',[])]"
else
    echo "✗ 服务器启动失败"
    echo "查看日志: tail -50 /tmp/flask_server.log"
    exit 1
fi
