# 🛠️ Sloan Toolkit - 多平台工具集

<div align="center">

[![Vue 3](https://img.shields.io/badge/Vue-3.5-42b883?logo=vue.js)](https://vuejs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.9-3178c6?logo=typescript)](https://www.typescriptlang.org/)
[![Vite](https://img.shields.io/badge/Vite-7.1-646cff?logo=vite)](https://vitejs.dev/)
[![Capacitor](https://img.shields.io/badge/Capacitor-7.4-119eff?logo=capacitor)](https://capacitorjs.com/)
[![Android](https://img.shields.io/badge/Android-Ready-3ddc84?logo=android)](https://developer.android.com/)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ed?logo=docker)](https://www.docker.com/)

**基于 Vue 3 + Capacitor 构建的现代化跨平台工具集**

支持 Web、Android 平台，提供天气查询、金融数据、日志分析等实用工具

[功能特性](#-功能特性) • [快速开始](#-快速开始) • [Android 应用](#-android-应用) • [文档](#-文档) • [贡献](#-贡献)

</div>

---

## ✨ 功能特性

### 📱 跨平台支持

- 🌐 **Web 应用** - 支持浏览器访问，响应式设计
- 📱 **Android 应用** - 原生 Android APK，使用 Capacitor 封装
- 🐳 **Docker 部署** - 一键容器化部署
- 🖥️ **局域网访问** - 支持局域网多设备访问

### 🧩 插件系统

#### 📡 信息插件
- 🌤️ **天气查询**
  - 全球城市实时天气
  - 中英文城市搜索
  - 城市收藏（最多10个）
  - 搜索历史（最近20条）
  - 详细气象数据（温度、湿度、风速、气压、体感温度）

#### 💰 金融插件
- 📊 **大盘指数** - 上证、深证、创业板、沪深300实时行情
- 📈 **K线图表** - 120天历史数据，支持交互缩放
- 💹 **资金流向** - 主力资金流入流出趋势分析
- 🔥 **热门股票** - 涨幅榜TOP5，实时更新
- 📊 **龙虎榜** - 市场热点股票展示
- 🌟 **期货行情** - TOP5期货合约涨幅排行

#### 📊 日志分析插件
- 📄 **PM:INFO 日志解析** - 专业的日志文件分析工具
- 📈 **数据可视化** - 电流、温度、电压多维度图表
- 📊 **统计分析** - 数据峰值、均值、异常检测
- 💾 **数据导出** - 支持CSV格式导出
- 🔍 **交互功能** - 缩放、平移、框选、重置

### 🎨 技术亮点

- ⚡ **Vue 3 Composition API** - 现代化响应式开发
- 📦 **Vite 构建** - 极速开发体验
- 🎯 **TypeScript** - 类型安全
- 🎨 **Element Plus** - 优雅的UI组件
- 📊 **ECharts 可视化** - 强大的图表功能
- 🔌 **模块化插件架构** - 易于扩展

---

## 🚀 快速开始

### 🌐 Web 部署

#### 方式一：Docker 部署（推荐）⭐

```bash
# 克隆项目
git clone https://github.com/chisl9403/webtest.git
cd webtest/sloan-toolkit-vue

# 一键部署
./deploy-docker.sh
```

访问：http://localhost:5000

#### 方式二：本地开发

**前置要求**：Node.js >= 16.x, Python >= 3.9

```bash
# 1. 克隆项目
git clone https://github.com/chisl9403/webtest.git
cd webtest/sloan-toolkit-vue

# 2. 配置 API 密钥
cp config.example.json config.json
# 编辑 config.json 添加 OpenWeatherMap API 密钥

# 3. 安装依赖
npm install
pip install -r requirements.txt

# 4. 启动服务
./start-auto.sh

# 或手动启动
# 终端1：python server.py
# 终端2：npm run dev
```

访问：http://localhost:3000

---

## 📱 Android 应用

### ✨ 特性

- ✅ 原生 Android APK
- ✅ 完整的 Web 功能
- ✅ Capacitor 7.4 支持
- ✅ 优化的移动端体验
- ✅ 4.77 MB 应用大小

### 📥 快速安装

#### 方式一：下载 APK（推荐）

1. 从 [Releases](https://github.com/chisl9403/webtest/releases) 下载最新的 `app-debug.apk`
2. 传输到 Android 设备
3. 安装并运行

#### 方式二：使用 ADB 安装

```bash
adb install android/app/build/outputs/apk/debug/app-debug.apk
```

### 🔨 从源码构建

#### 环境准备

**必需工具**：
- ✅ Node.js 18+
- ✅ Java JDK 17
- ✅ Android SDK (API 23+)
- ✅ Android Studio（可选）

**一键环境检查和安装**：

```bash
# 检查环境
.\install-capacitor-environment.ps1

# 如需配置环境变量
.\setup-env.ps1
```

#### 构建步骤

```bash
# 1. 进入项目目录
cd sloan-toolkit-vue

# 2. 安装依赖
npm install

# 3. 构建 Vue 项目
npm run build

# 4. 同步到 Android
npx cap sync android

# 5. 构建 APK
cd android
.\gradlew.bat assembleDebug

# APK 输出位置：
# android/app/build/outputs/apk/debug/app-debug.apk
```

#### 在 Android Studio 中开发

```bash
# 在 Android Studio 中打开
npx cap open android

# 或使用 VS Code（已配置快捷键）
# Ctrl+Shift+B: 构建项目
# Ctrl+Shift+S: 同步到 Android
# Ctrl+Shift+O: 在 Android Studio 中打开
```

### 📖 详细文档

- [**Android 开发完整指南**](./ANDROID_CAPACITOR_GUIDE.md) - 详细的开发步骤
- [**环境配置指南**](./CAPACITOR_ENVIRONMENT_SETUP.md) - 环境安装说明
- [**VS Code 开发指南**](./CAPACITOR_VSCODE_DEVELOPMENT_GUIDE.md) - IDE 配置
- [**Kotlin vs Capacitor 对比**](./KOTLIN_VS_CAPACITOR_COMPARISON.md) - 技术选型参考
- [**快速开始总结**](./CAPACITOR_SETUP_SUMMARY.md) - 快速入门

---

## 📦 技术栈

### 前端技术

| 技术 | 版本 | 说明 |
|------|------|------|
| Vue 3 | 3.5.22 | 渐进式 JavaScript 框架 |
| TypeScript | 5.9.3 | 类型安全的 JavaScript 超集 |
| Vite | 7.1.7 | 下一代前端构建工具 |
| Element Plus | 2.11.5 | Vue 3 组件库 |
| ECharts | 6.0.0 | 数据可视化图表库 |
| Vue Router | 4.6.3 | 官方路由管理器 |
| Pinia | 3.0.3 | Vue 状态管理库 |

### 移动端技术

| 技术 | 版本 | 说明 |
|------|------|------|
| Capacitor | 7.4.4 | 跨平台原生运行时 |
| Android SDK | API 23-35 | Android 开发工具包 |
| Gradle | 8.11.1 | Android 构建工具 |
| Java | JDK 17 | Android 开发语言 |

### 后端技术

| 技术 | 版本 | 说明 |
|------|------|------|
| Flask | 3.0.0 | Python Web 框架 |
| Flask-CORS | 5.0.0 | 跨域资源共享 |
| Matplotlib | 3.8.0 | 图表生成库 |

### 部署技术

| 技术 | 说明 |
|------|------|
| Docker | 容器化部署 |
| Docker Compose | 多容器编排 |
| Nginx | 反向代理（可选） |

---

## 📁 项目结构

```
sloan-toolkit-vue-android/
├── sloan-toolkit-vue/          # Vue 3 主项目
│   ├── src/                    # 前端源码
│   │   ├── plugins/           # 插件系统
│   │   │   ├── finance/      # 金融插件
│   │   │   ├── info/         # 信息插件
│   │   │   └── log-analyzer/ # 日志分析插件
│   │   ├── views/            # 页面视图
│   │   ├── router/           # 路由配置
│   │   ├── stores/           # Pinia 状态管理
│   │   └── types/            # TypeScript 类型
│   ├── backend/               # Flask 后端
│   │   ├── plugins/          # 后端插件
│   │   ├── config/           # 配置模块
│   │   └── utils/            # 工具函数
│   ├── android/               # Android 项目 ⭐
│   │   ├── app/              # Android 应用代码
│   │   ├── gradle/           # Gradle 配置
│   │   └── build.gradle      # 构建配置
│   ├── capacitor.config.ts    # Capacitor 配置 ⭐
│   ├── server.py             # Flask 入口
│   ├── Dockerfile            # Docker 镜像
│   ├── docker-compose.yml    # Docker 编排
│   └── package.json          # Node 依赖
│
├── *.md                        # 文档文件
│   ├── ANDROID_CAPACITOR_GUIDE.md
│   ├── CAPACITOR_ENVIRONMENT_SETUP.md
│   ├── CAPACITOR_VSCODE_DEVELOPMENT_GUIDE.md
│   ├── KOTLIN_VS_CAPACITOR_COMPARISON.md
│   └── ...
│
└── *.ps1, *.sh                # 自动化脚本
    ├── install-capacitor-environment.ps1
    ├── setup-env.ps1
    ├── deploy-docker.sh
    └── ...
```

---

## 🔧 配置说明

### API 配置

在 `config.json` 中配置服务：

```json
{
  "apiKey": "your_openweathermap_api_key",
  "plugins": {
    "info": {
      "enabled": true,
      "autoLoad": true,
      "defaultCity": "Beijing"
    },
    "finance": {
      "enabled": true,
      "autoLoad": true
    },
    "logAnalyzer": {
      "enabled": true
    }
  }
}
```

### Android 配置

在 `capacitor.config.ts` 中配置应用：

```typescript
const config: CapacitorConfig = {
  appId: 'com.sloan.toolkit',
  appName: 'Sloan Toolkit',
  webDir: 'dist'
};
```

### Gradle 镜像配置

已配置国内镜像加速（腾讯云 + 阿里云）：

```gradle
// android/build.gradle
repositories {
    maven { url 'https://maven.aliyun.com/repository/public/' }
    maven { url 'https://maven.aliyun.com/repository/google/' }
    google()
    mavenCentral()
}
```

---

## 📚 文档

### 核心文档

- [项目 Android 概览](./PROJECT_ANDROID_OVERVIEW.md) - 项目整体介绍
- [Android 方案对比](./ANDROID_SOLUTIONS_COMPARISON.md) - 多种方案对比分析

### Android 开发

- [Capacitor Android 完整指南](./ANDROID_CAPACITOR_GUIDE.md) ⭐ 推荐
- [环境配置详细说明](./CAPACITOR_ENVIRONMENT_SETUP.md)
- [快速开始总结](./CAPACITOR_SETUP_SUMMARY.md)
- [VS Code 开发指南](./CAPACITOR_VSCODE_DEVELOPMENT_GUIDE.md)

### 技术对比

- [Kotlin vs Capacitor 全面对比](./KOTLIN_VS_CAPACITOR_COMPARISON.md)
- [效果展示对比](./KOTLIN_CAPACITOR_EFFECTS_COMPARISON.md)

### Web 开发

- [Docker 部署指南](./sloan-toolkit-vue/DOCKER_GUIDE.md)
- [配置指南](./sloan-toolkit-vue/CONFIG_GUIDE.md)
- [部署总结](./sloan-toolkit-vue/DEPLOYMENT_SUMMARY.md)

---

## 🛠️ 开发指南

### Web 开发

```bash
# 启动开发服务器
npm run dev

# 构建生产版本
npm run build

# 代码检查
npm run lint

# 格式化代码
npm run format
```

### Android 开发

```bash
# 构建并同步
npm run build
npx cap sync android

# 打开 Android Studio
npx cap open android

# 构建 Debug APK
cd android
.\gradlew.bat assembleDebug

# 构建 Release APK（需要签名）
.\gradlew.bat assembleRelease
```

### VS Code 快捷键

- `Ctrl+Shift+B`: 构建 Vue 项目
- `Ctrl+Shift+S`: 同步到 Android
- `Ctrl+Shift+O`: 在 Android Studio 中打开

---

## 🐛 常见问题

### Android 开发

**Q: Java 版本不匹配？**
```bash
# 确保使用 JDK 17
java -version

# 配置 JAVA_HOME
.\setup-env.ps1
```

**Q: Android SDK 未找到？**
```bash
# 运行环境检查
.\install-capacitor-environment.ps1

# 手动设置 ANDROID_HOME
# Windows: C:\Users\你的用户名\AppData\Local\Android\Sdk
```

**Q: Gradle 下载慢？**
> 已配置国内镜像（腾讯云 + 阿里云），自动加速

**Q: 构建失败？**
```bash
# 清理并重新构建
cd android
.\gradlew.bat clean
.\gradlew.bat assembleDebug
```

### Web 开发

**Q: npm install 失败？**
```bash
# 清理缓存
npm cache clean --force
rm -rf node_modules
npm install
```

**Q: Docker 端口冲突？**
```yaml
# 修改 docker-compose.yml
ports:
  - "8080:5000"  # 改用其他端口
```

---

## 📝 更新日志

### v3.0.0 (2025-11-03) 🎉

**🚀 重大更新：Android 平台支持**

- ✨ **新增 Android 应用支持**
  - Capacitor 7.4 集成
  - 原生 Android APK 构建
  - 完整的移动端优化
  - 4.77 MB 应用体积

- 📚 **完善文档体系**
  - 8 个详细开发文档
  - Android 开发完整指南
  - 环境配置自动化脚本
  - VS Code 开发环境配置

- 🛠️ **开发工具增强**
  - 5 个自动化脚本
  - 环境检查和配置工具
  - VS Code 任务和快捷键
  - Gradle 国内镜像加速

- 🔧 **技术优化**
  - Java 17 兼容性修复
  - Android SDK 配置优化
  - 构建性能提升
  - 代码质量改进

### v2.0.0 (2025-11-02)

- ✨ 新增完整的金融插件功能
- 🐳 新增 Docker 容器化支持
- 📝 新增详细的部署文档
- 🚀 新增一键部署脚本

### v1.0.0 (2025-10-01)

- 🎉 初始版本发布
- ✨ 天气查询功能
- ✨ 日志分析功能
- ✨ 插件系统框架

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

### 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

### 开发分支

- `main`: 主分支，稳定版本
- `Android`: Android 开发分支 ⭐
- `feature/*`: 功能开发分支
- `bugfix/*`: Bug 修复分支

---

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

---

## 👨‍💻 作者

**Sloan Chi**

- GitHub: [@chisl9403](https://github.com/chisl9403)
- Repository: [webtest](https://github.com/chisl9403/webtest)

---

## 🙏 致谢

感谢以下开源项目：

- [Vue.js](https://vuejs.org/) - 渐进式 JavaScript 框架
- [Capacitor](https://capacitorjs.com/) - 跨平台原生运行时
- [Element Plus](https://element-plus.org/) - Vue 3 组件库
- [ECharts](https://echarts.apache.org/) - 数据可视化库
- [Flask](https://flask.palletsprojects.com/) - Python Web 框架
- [TypeScript](https://www.typescriptlang.org/) - JavaScript 的超集
- [Vite](https://vitejs.dev/) - 下一代构建工具
- [Docker](https://www.docker.com/) - 容器化平台

---

## 🔗 相关链接

### 官方文档

- [Vue 3 文档](https://vuejs.org/)
- [Capacitor 文档](https://capacitorjs.com/docs)
- [Android 开发文档](https://developer.android.com/)
- [Element Plus 文档](https://element-plus.org/)
- [ECharts 文档](https://echarts.apache.org/)

### API 服务

- [OpenWeatherMap API](https://openweathermap.org/api) - 天气数据
- [东方财富 API](https://www.eastmoney.com/) - 金融数据

### 开发工具

- [VS Code](https://code.visualstudio.com/) - 推荐编辑器
- [Android Studio](https://developer.android.com/studio) - Android 开发
- [Docker Desktop](https://www.docker.com/products/docker-desktop) - 容器管理

---

<div align="center">

**⭐ 如果这个项目对你有帮助，请给个 Star！**

**📱 支持 Web + Android 双平台**

[返回顶部](#️-sloan-toolkit---多平台工具集)

</div>
