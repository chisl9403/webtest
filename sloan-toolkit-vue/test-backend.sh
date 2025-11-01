#!/bin/bash
# 测试模块化后端的日志分析功能

echo "=== 测试后端服务 ==="
echo ""

# 1. 测试健康检查
echo "1. 测试健康检查端点..."
curl -s http://localhost:5002/ | python3 -m json.tool
echo ""
echo ""

# 2. 创建测试日志文件
echo "2. 创建测试 PM:INFO 日志文件..."
cat > /tmp/test_pm_info.log << 'EOF'
I>000000 PM:INFO curr=500 volt=4200 temp=25 charge=0
I>000001 PM:INFO curr=520 volt=4190 temp=26 charge=0
I>000002 PM:INFO curr=510 volt=4185 temp=27 charge=0
I>000003 PM:INFO curr=1200 volt=4300 temp=28 charge=1
I>000004 PM:INFO curr=1180 volt=4310 temp=29 charge=1
I>000005 PM:INFO curr=1150 volt=4320 temp=28 charge=1
I>000006 PM:INFO curr=500 volt=4250 temp=27 charge=0
I>000007 PM:INFO curr=490 volt=4240 temp=26 charge=0
I>000008 PM:INFO curr=480 volt=4230 temp=25 charge=0
I>000009 PM:INFO curr=470 volt=4220 temp=25 charge=0
EOF

echo "测试日志文件已创建: /tmp/test_pm_info.log"
echo ""

# 3. 测试日志分析 API
echo "3. 测试日志分析 API..."
RESPONSE=$(curl -s -X POST \
  -F "file=@/tmp/test_pm_info.log" \
  http://localhost:5002/api/analyze)

# 检查响应
if echo "$RESPONSE" | grep -q "graph"; then
    echo "✓ 日志分析成功！"
    echo ""
    echo "响应数据："
    echo "$RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
if 'stats' in data:
    print('统计数据:')
    for key, value in data['stats'].items():
        print(f'  {key}: {value}')
if 'graph' in data:
    print(f'图表数据长度: {len(data[\"graph\"])} 字符 (base64)')
"
else
    echo "✗ 日志分析失败"
    echo "响应内容："
    echo "$RESPONSE" | python3 -m json.tool 2>&1 || echo "$RESPONSE"
fi

echo ""
echo "=== 测试完成 ==="

# 清理
rm -f /tmp/test_pm_info.log
