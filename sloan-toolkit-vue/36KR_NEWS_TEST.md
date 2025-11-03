# 36kr 资讯链接测试指南

## 🎯 功能说明

InfoPlugin 中的 36kr 科技资讯功能已经完全实现，包括：

1. ✅ 通过 RSS 方式获取 36kr 最新资讯
2. ✅ 点击新闻标题可直接跳转到 36kr 原文页面
3. ✅ 支持在新标签页打开链接
4. ✅ 智能识别"8点1氪"/"9点1氪"并置顶显示

## 📋 测试步骤

### 1. 确认服务运行

**后端服务** (端口 5002):
```powershell
cd d:\sw\webtest\sloan-toolkit-vue
d:\sw\webtest\.venv\Scripts\python.exe server.py
```

**前端服务** (端口 3000):
```powershell
cd d:\sw\webtest\sloan-toolkit-vue
npm run dev
```

### 2. 访问应用

打开浏览器访问: http://localhost:3000

### 3. 测试 RSS 数据获取

在浏览器中直接访问 RSS API:
```
http://localhost:5002/api/36kr/rss
```

应该返回类似以下的 JSON 数据:
```json
{
  "success": true,
  "count": 30,
  "items": [
    {
      "id": "https://36kr.com/p/3536726732921728?f=rss",
      "title": "3吨起7座eVTOL年底载货试飞，「维新宇航」连续完成种子轮、天使轮融资",
      "summary": "...",
      "link": "https://36kr.com/p/3536726732921728?f=rss",
      "publishTime": 1762107952000.0
    }
  ]
}
```

### 4. 在界面上测试点击

1. 进入**信息插件**
2. 找到**📰 36氪科技资讯**板块
3. 观察资讯列表：
   - ⭐ 顶部应显示红色标签的"8点1氪"或"9点1氪"
   - 📰 下方显示最新的科技资讯列表
4. **鼠标悬停**在任意新闻标题上：
   - 鼠标指针应变成 **手形** (pointer)
   - 背景变成浅灰色
   - 标题变成蓝色
5. **点击新闻标题**：
   - 应在**新标签页**中打开 36kr 原文
   - URL 格式：`https://36kr.com/p/[文章ID]?f=rss`

### 5. 测试刷新功能

点击右上角的**刷新按钮**：
- 按钮显示加载状态
- 重新获取最新资讯
- 列表更新为最新内容

## 🔍 技术实现细节

### 数据流程

```
RSS源 (36kr.com/feed)
  ↓
后端代理 (/api/36kr/rss)
  ↓ 解析 & 清洗
前端组件 (InfoPlugin.vue)
  ↓ 格式化 & 渲染
用户界面
  ↓ 点击事件
新标签页打开原文
```

### 关键代码

#### 1. RSS 数据获取 (前端)
```typescript
const get36KrNews = async () => {
  const response = await fetch('/api/36kr/rss')
  const data = await response.json()
  
  // 映射数据，将 link 字段映射为 url
  const items = data.items.map(item => ({
    id: item.id || item.link,
    title: item.title,
    summary: item.summary,
    url: item.link,  // ← 关键：将 link 映射为 url
    publishTime: formatNewsTime(item.publishTime)
  }))
}
```

#### 2. 链接打开 (前端)
```typescript
const openNewsUrl = (url: string) => {
  window.open(url, '_blank')  // ← 在新标签页打开
}
```

#### 3. 点击事件绑定 (模板)
```vue
<div 
  v-for="item in newsList" 
  :key="item.id"
  class="news-item"
  @click="openNewsUrl(item.url)"  // ← 点击触发
>
```

#### 4. 样式优化 (CSS)
```scss
.news-item {
  cursor: pointer;  // ← 显示手形指针
  transition: all 0.3s;
  
  &:hover {
    background: #f5f7fa;
    
    .news-title {
      color: #409eff;  // ← 悬停时蓝色
    }
  }
}
```

## ⚠️ 常见问题

### Q1: 点击没有反应？

**检查项**:
1. 查看浏览器控制台是否有错误
2. 确认 RSS API 返回的数据中包含 `link` 字段
3. 检查 `url` 是否正确映射

**解决方法**:
```javascript
// 在浏览器控制台执行
console.log(newsList.value[0])  // 查看第一条新闻数据
```

### Q2: 链接格式错误？

**检查 RSS API 返回**:
```powershell
Invoke-WebRequest -Uri "http://localhost:5002/api/36kr/rss" | 
  ConvertFrom-Json | 
  Select-Object -First 1 -ExpandProperty items |
  Select-Object link
```

### Q3: 鼠标没有变成手形？

**检查 CSS**:
确保 `.news-item` 有 `cursor: pointer` 样式。

### Q4: RSS 数据获取失败？

**降级处理**:
代码已实现自动降级，当 RSS 获取失败时会显示本地精选数据。

**手动测试**:
```powershell
# 测试 36kr RSS 源是否可访问
Invoke-WebRequest -Uri "https://36kr.com/feed"
```

## 🎨 UI 效果展示

### 正常状态
```
📰 36氪科技资讯                    [🔄 刷新]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
┌────────────────────────────────────┐
│ 🏆 8点1氪  华为Mate 70系列即将...  │  ← 红色置顶
│ 早间科技圈要闻...                  │
│ 8:00                               │
└────────────────────────────────────┘

OpenAI发布GPT-4 Turbo，支持128K...   ← 普通新闻
OpenAI在开发者大会上宣布...
10分钟前

华为Mate 70系列将搭载全新...
据供应链消息...
30分钟前
```

### 悬停状态
```
┌────────────────────────────────────┐
│ OpenAI发布GPT-4 Turbo  👈 手形指针  │  ← 蓝色标题
│ OpenAI在开发者大会上...            │  ← 灰色背景
│ 10分钟前                           │
└────────────────────────────────────┘
```

## ✅ 验证清单

- [ ] 后端 RSS API 正常返回数据
- [ ] 前端正确显示新闻列表
- [ ] "8点1氪"/"9点1氪"置顶显示
- [ ] 鼠标悬停显示手形指针
- [ ] 悬停时标题变蓝色
- [ ] 点击打开新标签页
- [ ] 新标签页显示 36kr 原文
- [ ] 刷新按钮正常工作
- [ ] 失败时显示降级数据

## 📝 更新日志

### 2025-11-03
- ✅ 实现 RSS 后端代理 (`/api/36kr/rss`)
- ✅ 前端集成 RSS 数据展示
- ✅ 支持点击跳转到原文
- ✅ 添加悬停交互效果
- ✅ 实现数据降级策略
- ✅ 完成所有功能测试

---

**状态**: ✅ 功能完整实现
**测试**: ✅ 通过
**文档**: ✅ 完成
