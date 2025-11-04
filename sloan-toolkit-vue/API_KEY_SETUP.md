# 🔑 API Key 配置指南

## 📝 概述

本项目使用 OpenWeatherMap API 提供天气查询功能。需要配置有效的 API Key 才能正常使用天气插件。

---

## 🚀 快速配置

### 1️⃣ 获取 API Key

1. 访问 [OpenWeatherMap](https://openweathermap.org/api)
2. 注册免费账户
3. 在 [API Keys](https://home.openweathermap.org/api_keys) 页面生成 API Key
4. 复制你的 API Key（类似：`a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`）

**免费账户限制**：
- ✅ 每分钟 60 次调用
- ✅ 每月 1,000,000 次调用
- ✅ 足够个人使用

---

## 🔧 配置方法

### 方案 A：Web 开发环境

编辑 **根目录** 的 `config.json`：

```bash
# 进入项目根目录
cd sloan-toolkit-vue

# 编辑配置文件
notepad config.json  # Windows
# 或
nano config.json     # Linux/Mac
```

修改 `apiKey` 字段：

```json
{
    "apiKey": "你的真实API_KEY",
    "network": {
        "ipv4": {
            "host": "0.0.0.0",
            "lan": "192.168.1.100"
        }
    },
    "plugins": {
        "info": {
            "enabled": true,
            "autoLoad": true,
            "defaultCity": "Beijing"
        }
    }
}
```

### 方案 B：Android 编译

编辑 **public 目录** 的 `config.json`：

```bash
# 进入 public 目录
cd sloan-toolkit-vue/public

# 编辑配置文件
notepad config.json  # Windows
```

修改后的文件会在构建时被包含到 Android APK 中。

**重要**：每次修改后需要重新构建：

```bash
# 1. 构建 Vue 项目
npm run build

# 2. 同步到 Android
npx cap sync android

# 3. 构建 APK
cd android
.\gradlew.bat assembleDebug
```

---

## 📂 配置文件位置

### 项目结构

```
sloan-toolkit-vue/
├── config.json              ← Web 开发用配置
├── config.example.json      ← 配置模板
├── public/
│   ├── config.json         ← Android 编译用配置 ⭐
│   └── config.example.json
├── dist/
│   └── config.json         ← 构建后自动生成
└── android/
    └── app/src/main/assets/public/
        └── config.json     ← Android APK 中的配置
```

### 关键说明

- **根目录 config.json**：Web 开发时使用
- **public/config.json**：会被 Vite 复制到 dist 目录，最终打包进 Android APK ⭐
- 两个文件建议保持同步

---

## 🔄 自动同步脚本

创建 `sync-config.ps1` 脚本：

```powershell
# 同步配置文件
Copy-Item "config.json" "public\config.json" -Force
Write-Host "✓ Config synced to public directory"
```

使用方法：

```bash
# 修改根目录的 config.json 后运行
.\sync-config.ps1
```

---

## ✅ 验证配置

### 1. 检查配置文件是否存在

```powershell
# 检查根目录配置
Test-Path "config.json"

# 检查 public 目录配置
Test-Path "public\config.json"

# 检查构建输出
Test-Path "dist\config.json"
```

### 2. 验证 API Key 格式

有效的 API Key 特征：
- ✅ 32 位十六进制字符
- ✅ 只包含数字和小写字母
- ❌ 不是 `YOUR_OPENWEATHERMAP_API_KEY_HERE`
- ❌ 不包含中文或空格

### 3. 测试 API 调用

```bash
# 启动开发服务器
npm run dev

# 访问 http://localhost:3000
# 尝试查询天气，观察是否有错误提示
```

如果配置正确，应该能看到天气数据。如果失败，检查浏览器控制台错误信息。

---

## 🐛 常见问题

### Q1: API Key 无效

**错误提示**：`API key is invalid or missing`

**解决方法**：
1. 检查 API Key 是否正确复制（无多余空格）
2. 确认 OpenWeatherMap 账户已激活
3. 新生成的 API Key 可能需要等待 10-30 分钟才能生效

### Q2: Android APK 中天气功能不工作

**原因**：`public/config.json` 中未配置 API Key

**解决方法**：
```bash
# 1. 编辑 public/config.json
notepad public\config.json

# 2. 重新构建
npm run build
npx cap sync android
cd android
.\gradlew.bat assembleDebug
```

### Q3: 配置文件找不到

**错误提示**：`Failed to load config.json`

**检查**：
```bash
# Web 环境
Get-Content "config.json"

# Android 环境
Get-Content "public\config.json"

# 构建输出
Get-Content "dist\config.json"
```

### Q4: 多次修改配置未生效

**原因**：浏览器缓存或未重新构建

**解决方法**：
```bash
# 清除浏览器缓存（Ctrl+Shift+Delete）
# 或强制刷新（Ctrl+F5）

# 重新构建项目
npm run build
```

---

## 🔒 安全建议

### ⚠️ 不要泄露 API Key

1. **不要提交到 Git**

   `.gitignore` 应包含：
   ```
   config.json
   config.local.json
   public/config.json
   ```

2. **使用环境变量（可选）**

   对于生产环境，可以使用环境变量：
   ```javascript
   const apiKey = import.meta.env.VITE_OPENWEATHER_API_KEY || config.apiKey
   ```

3. **限制 API Key 权限**

   在 OpenWeatherMap 后台：
   - ✅ 限制 API 调用来源域名
   - ✅ 设置每日调用限额
   - ✅ 定期轮换 API Key

---

## 📝 配置模板

### 完整配置示例

```json
{
    "apiKey": "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6",
    "network": {
        "ipv4": {
            "host": "0.0.0.0",
            "lan": "192.168.1.100"
        },
        "ipv6": {
            "host": "::",
            "external": "2001:db8::1"
        }
    },
    "plugins": {
        "info": {
            "enabled": true,
            "autoLoad": true,
            "defaultCity": "Shanghai"
        },
        "logAnalyzer": {
            "enabled": true
        }
    },
    "settings": {
        "theme": "light",
        "language": "zh-CN"
    }
}
```

### 字段说明

| 字段 | 必填 | 说明 |
|------|------|------|
| `apiKey` | ✅ | OpenWeatherMap API Key |
| `network.ipv4.host` | ⚪ | IPv4 监听地址（默认 0.0.0.0） |
| `network.ipv4.lan` | ⚪ | 局域网 IP 地址 |
| `plugins.info.enabled` | ⚪ | 是否启用天气插件（默认 true） |
| `plugins.info.defaultCity` | ⚪ | 默认城市（默认 Beijing） |
| `settings.theme` | ⚪ | 主题（light/dark） |
| `settings.language` | ⚪ | 语言（zh-CN/en-US） |

---

## 🔗 相关链接

- [OpenWeatherMap API 文档](https://openweathermap.org/api)
- [OpenWeatherMap API Keys 管理](https://home.openweathermap.org/api_keys)
- [项目配置指南](./CONFIG_GUIDE.md)
- [Android 编译指南](./ANDROID_CAPACITOR_GUIDE.md)

---

## 📞 获取帮助

如果配置过程中遇到问题：

1. 检查本文档的 [常见问题](#-常见问题) 章节
2. 查看浏览器控制台的错误信息
3. 提交 [Issue](https://github.com/chisl9403/webtest/issues)

---

<div align="center">

**⭐ 配置完成后，即可享受完整的天气查询功能！**

</div>
