# 36kr RSS 功能使用指南

## 📰 功能说明

项目已集成 36kr RSS 订阅功能，可以实时获取最新的科技资讯。

## ✅ 功能特性

### 1. 后端 API
- **端点**: `/api/36kr/rss`
- **方法**: GET
- **功能**: 
  - 获取 36kr 最新文章
  - 自动解析 RSS 源
  - 提取标题、摘要、链接、发布时间
  - 智能识别"8点1氪"/"9点1氪"等特色栏目

### 2. 前端展示
- **位置**: 信息插件（InfoPlugin）
- **展示内容**:
  - ⭐ 置顶显示"8点1氪"/"9点1氪"
  - 📰 最新科技资讯列表
  - 🔗 点击跳转到原文
  - ⏰ 显示发布时间

### 3. 降级策略
- 当 RSS 获取失败时，自动显示本地精选数据
- 保证用户体验不中断

## 🚀 使用方法

### 后端 API 调用

```bash
# 使用 curl
curl http://localhost:5002/api/36kr/rss

# 使用 PowerShell
Invoke-WebRequest -Uri "http://localhost:5002/api/36kr/rss" | ConvertFrom-Json
```

### 前端集成

InfoPlugin.vue 中已经集成了 36kr RSS 功能：

```typescript
// 获取 36kr 资讯
const get36KrNews = async () => {
  newsLoading.value = true
  try {
    const response = await fetch('/api/36kr/rss')
    const data = await response.json()
    
    // 处理数据...
    if (data.items && data.items.length > 0) {
      // 优先显示"8点1氪"/"9点1氪"
      const topArticles = data.items.filter(item => 
        item.title.includes('8点1氪') || item.title.includes('9点1氪')
      )
      // ...
    }
  } catch (error) {
    // 降级到本地数据
  }
}
```

## 📊 API 响应格式

### 成功响应

```json
{
  "success": true,
  "count": 20,
  "feedTitle": "36氪",
  "feedLink": "https://36kr.com",
  "items": [
    {
      "id": "article-id",
      "title": "8点1氪｜华为Mate 70系列即将发布",
      "summary": "早间科技圈要闻摘要...",
      "link": "https://36kr.com/article/...",
      "publishTime": 1730620800000,
      "author": "36氪"
    }
  ]
}
```

### 失败响应

```json
{
  "success": false,
  "message": "请求失败: Connection timeout",
  "items": []
}
```

## 🛠️ 技术实现

### 后端实现
- **框架**: Flask
- **库**: feedparser, requests
- **文件**: `backend/plugins/rss_proxy/__init__.py`

### 关键代码

```python
@rss_proxy_bp.route('/36kr/rss', methods=['GET'])
def get_36kr_rss():
    """获取36氪RSS数据"""
    rss_url = 'https://36kr.com/feed'
    
    # 获取并解析 RSS
    response = requests.get(rss_url, headers=headers, timeout=10)
    feed = feedparser.parse(response.content)
    
    # 格式化数据
    items = []
    for entry in feed.entries:
        item = {
            'id': entry.get('id'),
            'title': entry.get('title'),
            'summary': clean_html(entry.get('summary')),
            'link': entry.get('link'),
            'publishTime': parse_time(entry.published_parsed)
        }
        items.append(item)
    
    return jsonify({'success': True, 'items': items})
```

## 🔧 配置说明

### 1. 依赖安装

```bash
pip install feedparser requests
```

### 2. 插件启用

在 `server.py` 中：

```python
from plugins.rss_proxy import rss_proxy_bp

app.register_blueprint(rss_proxy_bp, url_prefix='/api')
```

### 3. 前端代理配置

在 `vite.config.ts` 中：

```typescript
server: {
  proxy: {
    '/api': {
      target: 'http://localhost:5002',
      changeOrigin: true
    }
  }
}
```

## 📝 扩展开发

### 添加新的 RSS 源

1. 在 `backend/plugins/rss_proxy/__init__.py` 中添加新端点：

```python
@rss_proxy_bp.route('/techcrunch/rss', methods=['GET'])
def get_techcrunch_rss():
    rss_url = 'https://techcrunch.com/feed/'
    # 类似 36kr 的实现
```

2. 在前端调用新端点：

```typescript
const response = await fetch('/api/techcrunch/rss')
```

### 通用 RSS 代理

使用通用代理端点获取任意 RSS 源：

```bash
curl "http://localhost:5002/api/rss/proxy?url=https://example.com/feed"
```

## ⚠️ 注意事项

1. **网络要求**: 需要能访问 36kr.com
2. **频率限制**: 建议添加缓存机制，避免频繁请求
3. **错误处理**: 已实现降级策略，保证用户体验
4. **CORS**: 后端已配置 CORS，支持跨域请求

## 🎯 未来优化

- [ ] 添加 Redis 缓存，减少请求频率
- [ ] 支持更多科技媒体 RSS 源
- [ ] 添加关键词过滤功能
- [ ] 支持文章收藏和标记

## 📚 相关文档

- 36kr RSS 源: https://36kr.com/feed
- feedparser 文档: https://pythonhosted.org/feedparser/
- Flask 文档: https://flask.palletsprojects.com/

---

**状态**: ✅ 已实现并可用
**版本**: 2.0.0
**最后更新**: 2025-11-03
