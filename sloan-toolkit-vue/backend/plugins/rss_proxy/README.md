# 36氪 RSS 资讯集成方案

## 方案说明

使用36氪官方RSS源（`https://36kr.com/feed`）通过后端代理获取真实科技资讯。

## 架构

```
前端 (Vue) -> Vite代理 (/api/*) -> Flask后端 (/api/36kr/rss) -> 36氪RSS源
```

## 文件结构

```
backend/plugins/rss_proxy/
  └── __init__.py          # RSS代理插件
server.py                  # Flask主服务器（已集成rss_proxy插件）
start-backend.sh           # 后端启动脚本
src/plugins/info/
  └── InfoPlugin.vue       # 前端组件（已更新为RSS方案）
```

## 使用方法

### 1. 启动后端服务器

```bash
# 方式1：使用启动脚本（推荐）
./start-backend.sh

# 方式2：手动启动
python3 server.py
```

后端将运行在 `http://localhost:5002`

### 2. 启动前端开发服务器

```bash
npm run dev
```

前端将运行在 `http://localhost:3000` 或 `http://localhost:3001`

### 3. API接口

#### 获取36氪RSS
```
GET /api/36kr/rss
```

**响应示例：**
```json
{
  "success": true,
  "count": 30,
  "feedTitle": "36氪",
  "feedLink": "https://36kr.com",
  "items": [
    {
      "id": "https://36kr.com/p/...",
      "title": "新闻标题",
      "summary": "新闻摘要",
      "link": "https://36kr.com/p/...",
      "publishTime": 1730534400000,
      "author": "作者"
    }
  ]
}
```

#### 通用RSS代理
```
GET /api/rss/proxy?url=<RSS_URL>
```

## 功能特点

### 后端特性
- ✅ 解决CORS跨域问题
- ✅ 自动解析RSS格式
- ✅ 清理HTML标签
- ✅ 统一时间戳格式
- ✅ 错误处理和日志记录
- ✅ 支持任意RSS源代理

### 前端特性
- ✅ 自动识别"8点1氪/9点1氪"并置顶
- ✅ 特殊样式高亮显示每日简报
- ✅ 点击标题直接跳转文章
- ✅ 时间格式化显示
- ✅ 降级方案（后端不可用时显示本地数据）

## 数据流程

1. **前端请求**：Vue组件调用 `fetch('/api/36kr/rss')`
2. **Vite代理**：`/api/*` 请求转发到 `http://localhost:5002/api/*`
3. **Flask处理**：RSS代理插件处理请求
4. **获取RSS**：向36氪服务器请求RSS数据
5. **解析处理**：解析XML，提取数据，格式化
6. **返回JSON**：统一格式返回给前端
7. **前端渲染**：
   - 筛选"8点1氪/9点1氪"文章
   - 置顶显示（unshift到数组开头）
   - 添加特殊样式（红色标签+渐变背景）
   - 渲染新闻列表

## 依赖包

### Python后端
```bash
pip3 install feedparser requests flask flask-cors
```

- `feedparser`: RSS/Atom解析库
- `requests`: HTTP请求库
- `flask`: Web框架
- `flask-cors`: 跨域支持

### 前端
已在 `package.json` 中包含，无需额外安装。

## 测试命令

### 测试后端API
```bash
# 测试健康检查
curl http://localhost:5002/

# 测试36氪RSS
curl http://localhost:5002/api/36kr/rss | python3 -m json.tool

# 测试通用代理
curl "http://localhost:5002/api/rss/proxy?url=https://example.com/rss" | python3 -m json.tool
```

### 测试前端代理
```bash
# 通过前端代理访问
curl http://localhost:3001/api/36kr/rss | python3 -m json.tool
```

## 故障排查

### 1. 端口被占用
```bash
# 查找占用端口的进程
lsof -ti:5002

# 杀死进程
lsof -ti:5002 | xargs kill -9
```

### 2. 依赖包缺失
```bash
# 重新安装依赖
pip3 install feedparser requests
```

### 3. RSS获取失败
查看后端日志：
```bash
tail -f /tmp/flask_server.log
```

常见原因：
- 网络连接问题
- 36氪服务器临时不可用
- 请求被限流

解决方案：
- 等待并重试
- 前端会自动降级到本地数据

### 4. 前端显示本地数据
检查：
1. 后端是否启动：`curl http://localhost:5002/`
2. 代理配置是否正确：查看 `vite.config.ts`
3. 浏览器控制台是否有错误

## 性能优化建议

### 缓存RSS数据
在Flask后端添加缓存：
```python
from functools import lru_cache
from datetime import datetime, timedelta

@lru_cache(maxsize=1)
def get_cached_rss(cache_time):
    # 实现缓存逻辑
    pass
```

### 定时更新
使用后台任务定期更新：
```python
from apscheduler.schedulers.background import BackgroundScheduler

scheduler = BackgroundScheduler()
scheduler.add_job(update_rss_cache, 'interval', minutes=5)
scheduler.start()
```

## 扩展其他RSS源

### 添加新的RSS源
在 `backend/plugins/rss_proxy/__init__.py` 中添加新路由：

```python
@rss_proxy_bp.route('/tech-news/rss', methods=['GET'])
def get_tech_news_rss():
    rss_url = 'https://example.com/feed'
    # 复用相同的解析逻辑
    ...
```

### 前端调用
```typescript
const response = await fetch('/api/tech-news/rss')
const data = await response.json()
```

## 参考链接

- 36氪官网：https://36kr.com
- 36氪RSS源：https://36kr.com/feed
- feedparser文档：https://feedparser.readthedocs.io/
- Flask文档：https://flask.palletsprojects.com/
