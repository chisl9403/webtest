# 🛠️ Sloan 的工具集

基于 Vue 3 + TypeScript + Vite 构建的现代化插件系统，提供天气查询、金融数据、日志分析等实用工具。

[![Vue 3](https://img.shields.io/badge/Vue-3.4-42b883?logo=vue.js)](https://vuejs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.6-3178c6?logo=typescript)](https://www.typescriptlang.org/)
[![Vite](https://img.shields.io/badge/Vite-7.1-646cff?logo=vite)](https://vitejs.dev/)
[![Element Plus](https://img.shields.io/badge/Element_Plus-2.5-409eff)](https://element-plus.org/)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ed?logo=docker)](https://www.docker.com/)

## ✨ 功能特性

### 📡 信息插件

- 🌤️ **天气查询** - 全球城市天气信息
  - 支持中英文城市搜索
  - 城市收藏和历史记录
  - 详细天气数据（温度、湿度、风速、气压等）

### 💰 金融插件

- 📊 **大盘指数** - 实时显示上证、深证、创业板、沪深300指数
- 📈 **K线图表** - 120天历史数据，支持交互缩放
- 💹 **资金流向** - 主力资金流入流出趋势分析
- 🔥 **热门股票** - 涨幅榜TOP5，实时更新
- 📊 **龙虎榜** - 市场热点股票展示
- 🌟 **期货行情** - TOP5期货合约涨幅排行

### 📊 日志分析插件

- 📄 **PM:INFO 日志解析** - 支持日志文件上传和分析
- 📈 **数据可视化** - 电流、温度、电压趋势图表
- 📊 **统计分析** - 数据峰值、均值、异常检测
- 💾 **数据导出** - 支持CSV格式导出

## 🚀 快速开始

### 🐳 方式一：Docker 部署（推荐）⭐

**适用于 Mac、Windows 和 Ubuntu，一键部署！**

#### 前置要求
- Docker Desktop (Mac/Windows) 或 Docker Engine (Ubuntu)
- Docker Compose V2

#### 一键部署

```bash
# 克隆项目
git clone https://github.com/chisl9403/webtest.git
cd webtest/sloan-toolkit-vue

# 运行自动部署脚本
./deploy-docker.sh
```

部署脚本会自动：
- ✅ 检测操作系统和 Docker 环境
- ✅ 检查端口占用情况
- ✅ 构建 Docker 镜像
- ✅ 启动服务容器
- ✅ 等待服务就绪
- ✅ 显示访问地址

#### 手动部署

```bash
# 构建镜像
docker compose build

# 启动服务（生产模式）
docker compose up -d

# 启动服务（开发模式，带热重载）
docker compose --profile dev up -d

# 查看日志
docker compose logs -f

# 查看服务状态
docker compose ps

# 停止服务
docker compose down
```

#### 访问地址

- 🌐 **应用首页**: http://localhost:5000
- 📡 **API 接口**: http://localhost:5000/api
- 🏥 **健康检查**: http://localhost:5000/health
- 🔧 **开发模式前端**: http://localhost:3001 (仅开发模式)

#### Docker 命令速查

```bash
# 查看日志
docker compose logs -f sloan-toolkit

# 进入容器
docker compose exec sloan-toolkit sh

# 重启服务
docker compose restart

# 清理并重新部署
docker compose down -v
docker compose build --no-cache
docker compose up -d
```

📚 **详细 Docker 文档**: [DOCKER_GUIDE.md](./DOCKER_GUIDE.md)

---

### 💻 方式二：本地开发

#### 前置要求

- Node.js >= 16.x
- Python >= 3.9
- npm 或 yarn

#### 1️⃣ 克隆项目

```bash
git clone https://github.com/chisl9403/webtest.git
cd webtest/sloan-toolkit-vue
```

#### 2️⃣ 配置文件

```bash
# 复制配置模板
cp config.example.json config.json
```

编辑 `config.json`，添加天气 API 密钥：

```json
{
  "apiKey": "your_openweathermap_api_key_here",
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

> 💡 获取免费 API 密钥：[OpenWeatherMap](https://openweathermap.org/api)

#### 3️⃣ 安装依赖

**前端依赖：**
```bash
npm install
```

**后端依赖：**
```bash
pip install -r requirements.txt
```

#### 4️⃣ 启动服务

**方式 A：使用启动脚本（推荐）**
```bash
# 一键启动前后端
./start-auto.sh

# 停止服务
./stop-auto.sh
```

**方式 B：手动启动**

终端 1 - 启动后端：
```bash
python server.py
# 或使用启动脚本
./start-backend.sh
```

终端 2 - 启动前端：
```bash
npm run dev
```

#### 5️⃣ 访问应用

- **前端开发服务器**: http://localhost:3000
- **后端 API**: http://localhost:5000

#### 6️⃣ 构建生产版本

```bash
# 构建前端
npm run build

# 预览生产版本
npm run preview
```

## 📦 技术栈

### 前端
- **框架**: Vue 3.4+ (Composition API)
- **构建工具**: Vite 7.1+
- **UI 组件库**: Element Plus 2.5+
- **图表库**: ECharts 5.x + vue-echarts 7.x
- **状态管理**: Pinia 3.0+
- **路由**: Vue Router 4.6+
- **语言**: TypeScript 5.6+
- **样式**: SCSS

### 后端
- **框架**: Flask 3.0+
- **数据可视化**: Matplotlib 3.8+
- **RSS 解析**: feedparser 6.0+
- **HTTP 客户端**: requests 2.31+

### 部署
- **容器化**: Docker + Docker Compose
- **多阶段构建**: 优化镜像体积
- **健康检查**: 自动容器健康监测

## 📁 项目结构

```
sloan-toolkit-vue/
├── src/                    # 前端源码
│   ├── plugins/           # 插件目录
│   │   ├── finance/      # 金融插件
│   │   ├── info/         # 信息插件
│   │   └── log-analyzer/ # 日志分析插件
│   ├── views/            # 页面视图
│   ├── router/           # 路由配置
│   ├── stores/           # 状态管理
│   └── types/            # 类型定义
├── backend/               # 后端源码
│   ├── config/           # 后端配置
│   ├── plugins/          # 后端插件
│   │   ├── log_analyzer/ # 日志分析
│   │   └── rss_proxy/    # RSS代理
│   └── utils/            # 工具函数
├── public/               # 静态资源
├── testlog/              # 测试日志文件
├── server.py             # Flask 后端入口
├── Dockerfile            # Docker 镜像配置
├── docker-compose.yml    # Docker Compose 配置
├── requirements.txt      # Python 依赖
├── package.json          # Node.js 依赖
├── deploy-docker.sh      # 自动部署脚本
├── start-auto.sh         # 启动脚本
└── stop-auto.sh          # 停止脚本
```

## 🔌 插件系统

### 插件结构

每个插件都遵循统一的结构：

```
plugins/
└── your-plugin/
    ├── index.ts           # 插件注册
    ├── YourPlugin.vue     # 主组件
    ├── types/            # 类型定义
    └── README.md         # 插件文档
```

### 添加新插件

1. 在 `src/plugins/` 创建插件目录
2. 实现插件组件和类型定义
3. 在 `index.ts` 中注册插件
4. 在配置文件中启用插件

详见：[插件开发指南](./src/plugins/info/PLUGIN_STRUCTURE.md)

## 📊 日志分析功能

### 测试日志文件

项目提供了 `testlog/` 文件夹用于存放测试日志文件：

- **位置**: 项目根目录下的 `testlog/` 文件夹
- **格式**: 仅支持 `.log` 格式文件
- **大小限制**: 单个文件不超过 30MB
- **用途**: 通过日志分析插件上传并分析

### 日志格式要求

日志文件应包含时间戳、电流、温度、电压等数据，格式示例：

```
2024-01-01 10:00:00,123 PM:INFO Current=1.23A Temp=25.5C Voltage=3.7V
```

## 🛠️ 开发指南

### 代码规范

```bash
# 代码检查
npm run lint

# 代码格式化
npm run format
```

### 环境变量

支持通过环境变量配置：

```bash
# .env 文件
VITE_API_BASE_URL=http://localhost:5000
FLASK_ENV=development
```

### 调试

**前端调试：**
- 浏览器开发者工具
- Vue DevTools 插件

**后端调试：**
- Flask 调试模式
- Python debugger (pdb)

## 🚢 部署

### 生产环境部署

1. **使用 Docker（推荐）**
   ```bash
   docker compose build
   docker compose up -d
   ```

2. **使用 Nginx 反向代理**
   ```nginx
   server {
       listen 80;
       server_name your-domain.com;
       
       location / {
           proxy_pass http://localhost:5000;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
       }
   }
   ```

3. **启用 HTTPS**
   ```bash
   certbot --nginx -d your-domain.com
   ```

详见：[Docker 部署指南](./DOCKER_GUIDE.md)

## 🐛 常见问题

### Docker 相关

**Q: 端口被占用？**
```bash
# 修改 docker-compose.yml 中的端口映射
ports:
  - "8080:5000"  # 改用其他端口
```

**Q: 容器无法启动？**
```bash
# 查看日志
docker compose logs -f

# 重新构建
docker compose build --no-cache
docker compose up -d
```

### 本地开发

**Q: npm install 失败？**
```bash
# 清理缓存
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
```

**Q: Python 依赖安装失败？**
```bash
# 使用虚拟环境
python -m venv venv
source venv/bin/activate  # Mac/Linux
# 或
.\venv\Scripts\activate   # Windows
pip install -r requirements.txt
```

## 📝 更新日志

### v2.0.0 (2025-11-02)

- ✨ 新增完整的金融插件功能
  - K线图表（120天数据）
  - 资金流向可视化
  - 龙虎榜TOP5
  - 期货行情
  - 热门股票
- 🐳 新增 Docker 容器化支持
- 📝 新增详细的部署文档
- 🚀 新增一键部署脚本
- 🔧 优化插件系统架构
- 🐛 修复多个API兼容性问题

### v1.0.0

- 🎉 初始版本发布
- ✨ 天气查询功能
- ✨ 日志分析功能
- ✨ 插件系统框架

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License

## 👨‍💻 作者

**Sloan Chi** - [GitHub](https://github.com/chisl9403)

## 🙏 鸣谢

- [Vue.js](https://vuejs.org/)
- [Element Plus](https://element-plus.org/)
- [ECharts](https://echarts.apache.org/)
- [Flask](https://flask.palletsprojects.com/)
- [Docker](https://www.docker.com/)

---

⭐ 如果这个项目对你有帮助，请给个 Star！
