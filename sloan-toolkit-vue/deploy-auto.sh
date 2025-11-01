#!/bin/bash
# 自动化部署脚本 - 无需确认

set -e

PROJECT_DIR="/Users/chishiliang/sw/test/sloan-toolkit-vue"
cd "$PROJECT_DIR"

echo "🚀 自动化部署流程..."

# 1. 停止服务
echo "1️⃣ 停止服务..."
killall -9 node python3 Python 2>/dev/null || true
sleep 2

# 2. 清理临时文件
echo "2️⃣ 清理临时文件..."
rm -f backend.log flask.log server_output.log nohup.out *.pid 2>/dev/null || true

# 3. Git 提交（自动添加所有变更）
echo "3️⃣ 提交代码..."
cd /Users/chishiliang/sw/test

# 自动添加所有变更
git add -A

# 检查是否有变更
if git diff --cached --quiet; then
    echo "   没有需要提交的变更"
else
    # 自动生成提交信息（使用时间戳）
    COMMIT_MSG="chore: auto deploy at $(date '+%Y-%m-%d %H:%M:%S')"
    git commit -m "$COMMIT_MSG"
    echo "   ✅ 提交完成: $COMMIT_MSG"
fi

# 4. 推送到远程
echo "4️⃣ 推送到远程仓库..."
git push origin main

echo ""
echo "✅ 自动化部署完成！"
echo ""
echo "📝 下次使用:"
echo "   启动服务: ./start-auto.sh"
echo "   停止服务: ./stop-auto.sh"
echo "   自动部署: ./deploy-auto.sh"
