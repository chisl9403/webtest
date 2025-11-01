# Sloan 工具集 - 配置指南

## 🔐 隐私与安全配置

本项目使用本地配置文件管理敏感信息，确保 API 密钥和网络配置不会上传到远程仓库。

### 配置文件说明

| 文件 | 用途 | 是否上传Git |
|------|------|-------------|
| `config.local.json` | **本地配置**（包含真实API key） | ❌ 不上传 |
| `config.example.json` | 配置模板（占位符） | ✅ 上传 |
| `.env.local` | 本地环境变量 | ❌ 不上传 |
| `.env.example` | 环境变量模板 | ✅ 上传 |

## 🚀 首次配置步骤

### 1. 复制配置模板

```bash
cd sloan-toolkit-vue

# 复制配置文件
cp config.example.json config.local.json

# 复制环境变量文件（可选）
cp .env.example .env.local
```

### 2. 编辑 config.local.json

```json
{
  "apiKey": "你的OpenWeatherMap API Key",
  "network": {
    "ipv4": {
      "host": "0.0.0.0",
      "lan": "你的局域网IP（如：192.168.1.100）"
    },
    "ipv6": {
      "host": "::",
      "external": "你的IPv6地址（如果有）"
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
    }
  },
  "settings": {
    "theme": "light",
    "language": "zh-CN"
  }
}
```

### 3. 获取 API 密钥

**OpenWeatherMap API Key:**

1. 访问 https://openweathermap.org/api
2. 注册账号（免费）
3. 在 API keys 页面获取密钥
4. 将密钥填入 `config.local.json` 的 `apiKey` 字段

### 4. 配置网络信息（可选）

如需在局域网或IPv6环境下使用，可配置网络信息：

```bash
# 查看本机IP地址
ifconfig | grep "inet "      # IPv4
ifconfig | grep "inet6"      # IPv6
```

将获取的IP地址填入配置文件的 `network` 部分。

## 🔒 安全注意事项

### ⚠️ 重要提醒

- ✅ `config.local.json` 已添加到 `.gitignore`，不会上传到 Git
- ✅ `.env.local` 已添加到 `.gitignore`，不会上传到 Git
- ❌ **切勿**将真实 API 密钥提交到 Git 仓库
- ❌ **切勿**在公共场合分享包含真实密钥的配置文件

### 配置文件优先级

应用程序会按以下优先级加载配置：

1. `config.local.json` （优先，包含真实配置）
2. `config.json` （回退，使用占位符）
3. 环境变量 `.env.local` （可选）

### 团队协作

如果需要分享项目给他人：

1. 提供 `config.example.json` 作为配置模板
2. 在文档中说明如何获取 API 密钥
3. 让团队成员自行创建 `config.local.json`
4. **不要分享自己的 `config.local.json`**

## 📋 配置项说明

### apiKey
- **类型**: String
- **必需**: 是
- **说明**: OpenWeatherMap API 密钥，用于查询天气信息

### network.ipv4
- **host**: 服务监听地址（默认: `0.0.0.0`）
- **lan**: 局域网访问地址（用于文档说明）

### network.ipv6
- **host**: IPv6监听地址（默认: `::`，支持双栈）
- **external**: 外网IPv6地址（用于远程访问）

### plugins
- **info**: 信息插件配置（天气、股票）
  - `enabled`: 是否启用
  - `autoLoad`: 是否自动加载
  - `defaultCity`: 默认城市
- **logAnalyzer**: 日志分析插件配置
  - `enabled`: 是否启用

### settings
- **theme**: 主题（`light` / `dark`）
- **language**: 语言（`zh-CN` / `en-US`）

## 🛠️ 故障排查

### 问题：提示"请创建 config.local.json 文件"

**解决方案：**
```bash
cp config.example.json config.local.json
# 然后编辑 config.local.json 填入真实API key
```

### 问题：天气查询失败

**可能原因：**
1. API key 未配置或无效
2. API key 配置了占位符 `YOUR_API_KEY_HERE`
3. OpenWeatherMap 服务不可用

**解决方案：**
1. 检查 `config.local.json` 中的 `apiKey` 是否为真实密钥
2. 访问 https://openweathermap.org/ 验证账号状态
3. 检查网络连接

### 问题：局域网无法访问

**解决方案：**
1. 确认防火墙设置允许端口 3001 和 5002
2. 检查 `vite.config.ts` 中的 `host` 配置
3. 使用正确的局域网IP地址访问

## 📚 相关文档

- [项目主文档](./README.md)
- [开发指南](./README.md#📝-开发新插件)
- [日志分析功能](./testlog/README.md)
