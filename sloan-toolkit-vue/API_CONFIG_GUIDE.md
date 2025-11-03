# API 配置指南

## 📋 配置文件说明

项目支持三个配置文件，按以下优先级加载：

1. **config.local.json** ⭐（优先级最高）
   - 本地配置文件
   - 不会提交到 Git
   - 用于存储个人 API 密钥和本地设置

2. **config.json** 
   - 通用配置文件
   - 可选择提交到 Git（如果不含敏感信息）
   - 团队共享的配置

3. **config.example.json**（优先级最低）
   - 配置模板
   - 仅供参考，不会被实际使用

## 🔑 获取 OpenWeatherMap API Key

### 1. 注册账号
访问：https://openweathermap.org/api

### 2. 获取免费 API Key
- 登录后进入：https://home.openweathermap.org/api_keys
- 复制 API Key

### 3. 配置 API Key

编辑 `config.local.json` 文件：

```json
{
  "apiKey": "你的真实API_Key",
  "network": {
    "ipv4": {
      "host": "0.0.0.0",
      "lan": "10.101.6.160"
    },
    "ipv6": {
      "host": "::",
      "external": "YOUR_IPV6_ADDRESS_HERE"
    }
  },
  "plugins": {
    "info": {
      "enabled": true,
      "autoLoad": true,
      "defaultCity": "Beijing"
    },
    "logAnalyzer": {
      "enabled": true
    },
    "rssProxy": {
      "enabled": false
    }
  },
  "settings": {
    "theme": "light",
    "language": "zh-CN"
  }
}
```

## ✅ 验证配置

启动服务器时会自动检查配置：

```bash
cd d:\sw\webtest\sloan-toolkit-vue
python server.py
```

你会看到：

```
============================================================
配置文件检查
============================================================
✅ 已配置 - config.local.json
         API Key: 1a2b3c4d...xyz
============================================================
✅ 使用配置: config.local.json
============================================================
```

## ⚠️ 注意事项

1. **不要提交 API Key 到 Git**
   - `config.local.json` 已在 `.gitignore` 中
   - 确保不要在 `config.json` 中写入真实 API Key

2. **API Key 格式**
   - 通常是 32 位字符串
   - 示例：`1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p`

3. **免费额度限制**
   - 免费版：60 次/分钟，1,000,000 次/月
   - 足够个人使用

## 🔧 故障排除

### 问题：提示 "未配置（占位符）"

**原因**：API Key 包含占位符文本

**解决**：
```json
// ❌ 错误
"apiKey": "YOUR_OPENWEATHERMAP_API_KEY_HERE"

// ✅ 正确
"apiKey": "1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p"
```

### 问题：天气功能无法使用

**检查步骤**：
1. 确认 API Key 已正确配置
2. 检查网络连接
3. 查看浏览器控制台错误信息
4. 确认后端服务正在运行（端口 5002）

## 📁 文件位置

```
sloan-toolkit-vue/
├── config.example.json     # 配置模板（参考）
├── config.json             # 通用配置（可选）
├── config.local.json       # 本地配置（优先）⭐
└── server.py              # 后端服务
```

## 🚀 快速开始

```bash
# 1. 复制配置模板
cp config.example.json config.local.json

# 2. 编辑配置文件，添加你的 API Key
notepad config.local.json

# 3. 启动服务
python server.py

# 4. 启动前端（新终端）
npm run dev
```

---

**提示**：配置完成后，记得重启服务以使配置生效！
