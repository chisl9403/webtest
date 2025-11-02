# Sloan Toolkit - Docker 部署指南

## 📦 跨平台支持

本项目已配置 Docker 容器化，支持在 **Mac**、**Windows** 和 **Ubuntu** 上一键部署运行。

## 🚀 快速开始

### 前置要求

- Docker Desktop (Mac/Windows) 或 Docker Engine (Ubuntu)
- Docker Compose V2

#### 安装 Docker

**Mac:**
```bash
# 使用 Homebrew
brew install --cask docker

# 或下载安装包
# https://www.docker.com/products/docker-desktop
```

**Windows:**
```powershell
# 下载 Docker Desktop for Windows
# https://www.docker.com/products/docker-desktop

# 确保启用 WSL2
wsl --install
```

**Ubuntu:**
```bash
# 安装 Docker Engine
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 安装 Docker Compose
sudo apt-get update
sudo apt-get install docker-compose-plugin

# 将当前用户加入 docker 组
sudo usermod -aG docker $USER
newgrp docker
```

### 🎯 部署方式

#### 方式一：生产模式（推荐）

构建并启动完整应用（前端构建产物 + 后端服务）：

```bash
# 构建镜像
docker compose build

# 启动服务
docker compose up -d

# 查看日志
docker compose logs -f

# 停止服务
docker compose down
```

访问地址：
- **后端 API**: http://localhost:5000
- **前端页面**: 由后端提供静态文件服务

#### 方式二：开发模式

启动带热重载的开发环境：

```bash
# 启动包括开发前端的所有服务
docker compose --profile dev up -d

# 前端开发服务器
docker compose --profile dev up sloan-frontend-dev
```

访问地址：
- **开发前端**: http://localhost:3001
- **后端 API**: http://localhost:5000

#### 方式三：仅后端开发

如果只需要后端服务（本地前端开发）：

```bash
# 仅启动主应用
docker compose up sloan-toolkit -d
```

本地前端开发：
```bash
npm install
npm run dev
```

## 🔧 常用命令

### 构建与启动

```bash
# 重新构建镜像
docker compose build --no-cache

# 后台启动
docker compose up -d

# 前台启动（查看实时日志）
docker compose up

# 启动指定服务
docker compose up sloan-toolkit -d
```

### 日志查看

```bash
# 查看所有服务日志
docker compose logs

# 实时跟踪日志
docker compose logs -f

# 查看指定服务日志
docker compose logs -f sloan-toolkit
```

### 容器管理

```bash
# 查看运行状态
docker compose ps

# 重启服务
docker compose restart

# 停止服务
docker compose stop

# 停止并删除容器
docker compose down

# 停止并删除容器、网络、卷
docker compose down -v
```

### 进入容器调试

```bash
# 进入主容器
docker compose exec sloan-toolkit sh

# 进入前端开发容器
docker compose exec sloan-frontend-dev sh

# 查看 Python 环境
docker compose exec sloan-toolkit python --version

# 查看已安装的包
docker compose exec sloan-toolkit pip list
```

## 📁 目录结构

```
sloan-toolkit-vue/
├── Dockerfile              # Docker 镜像构建文件
├── docker-compose.yml      # Docker Compose 配置
├── .dockerignore          # Docker 构建忽略文件
├── requirements.txt       # Python 依赖
├── package.json          # Node.js 依赖
├── server.py             # Flask 后端入口
├── backend/              # 后端代码
│   ├── config/          # 配置
│   ├── plugins/         # 插件
│   └── utils/           # 工具函数
└── src/                 # 前端源码
    ├── plugins/        # Vue 插件
    └── views/          # 页面组件
```

## 🔐 环境配置

### 配置文件

项目支持多级配置：

1. `config.json` - 基础配置
2. `config.local.json` - 本地开发配置（不提交到 Git）

在 Docker 中使用配置：

```yaml
# docker-compose.yml
volumes:
  - ./config.json:/app/config.json
  - ./config.local.json:/app/config.local.json  # 可选
```

### 环境变量

在 `docker-compose.yml` 中配置：

```yaml
environment:
  - FLASK_ENV=production          # Flask 环境
  - PYTHONUNBUFFERED=1           # Python 输出不缓冲
  - VITE_API_BASE_URL=http://localhost:5000  # API 地址
```

## 🌐 端口映射

| 服务 | 容器端口 | 主机端口 | 说明 |
|------|---------|---------|------|
| Flask 后端 | 5000 | 5000 | API 服务 |
| Vite 开发 | 3000 | 3001 | 前端开发服务器 |

修改主机端口：

```yaml
# docker-compose.yml
ports:
  - "8080:5000"  # 将后端映射到主机 8080 端口
```

## 🔍 健康检查

容器包含健康检查机制：

```bash
# 查看健康状态
docker compose ps

# 手动健康检查
curl http://localhost:5000/health
```

健康检查配置：

```yaml
healthcheck:
  test: ["CMD", "python", "-c", "import requests; requests.get('http://localhost:5000/health')"]
  interval: 30s      # 每 30 秒检查一次
  timeout: 10s       # 超时时间
  retries: 3         # 重试次数
  start_period: 10s  # 启动等待时间
```

## 🐛 故障排查

### 1. 容器无法启动

```bash
# 查看详细日志
docker compose logs sloan-toolkit

# 检查容器状态
docker compose ps -a

# 重新构建
docker compose build --no-cache
docker compose up -d
```

### 2. 端口被占用

```bash
# Mac/Linux 查看端口占用
lsof -i :5000

# Windows 查看端口占用
netstat -ano | findstr :5000

# 修改 docker-compose.yml 中的端口映射
ports:
  - "5001:5000"
```

### 3. 前端无法连接后端

检查 API 地址配置：

```bash
# 进入容器
docker compose exec sloan-toolkit sh

# 测试后端服务
curl http://localhost:5000/health
```

修改前端 API 配置：

```javascript
// vite.config.ts
server: {
  proxy: {
    '/api': {
      target: 'http://sloan-toolkit:5000',  // Docker 网络内部地址
      changeOrigin: true
    }
  }
}
```

### 4. 权限问题（Linux）

```bash
# 确保 Docker 守护进程运行
sudo systemctl start docker

# 将用户加入 docker 组
sudo usermod -aG docker $USER

# 重新登录或执行
newgrp docker
```

### 5. 依赖安装失败

```bash
# 清理并重新构建
docker compose down -v
docker system prune -a
docker compose build --no-cache
```

## 📊 性能优化

### 多阶段构建优化

Dockerfile 使用多阶段构建，减小镜像体积：

```dockerfile
# 前端构建阶段（不保留 node_modules）
FROM node:20-alpine AS frontend-builder
RUN npm ci --only=production
RUN npm run build

# 运行阶段（仅复制构建产物）
FROM python:3.11-slim
COPY --from=frontend-builder /app/dist ./dist
```

### 镜像体积对比

- 完整镜像：~500MB
- 优化后镜像：~300MB

### 启动时间优化

```yaml
# docker-compose.yml
depends_on:
  sloan-toolkit:
    condition: service_healthy  # 等待服务健康后再启动依赖服务
```

## 🔄 更新部署

### 拉取最新代码并重新部署

```bash
# 停止服务
docker compose down

# 拉取代码
git pull origin main

# 重新构建并启动
docker compose build --no-cache
docker compose up -d
```

### 热更新（开发模式）

```bash
# 使用卷挂载，代码修改自动生效
docker compose --profile dev up -d

# 后端代码修改后自动重载（需要配置 Flask debug 模式）
# 前端代码修改后浏览器自动刷新
```

## 📝 生产环境部署建议

### 1. 使用环境变量

```bash
# 创建 .env 文件
cat > .env << EOF
FLASK_ENV=production
SECRET_KEY=your-secret-key-here
DATABASE_URL=postgresql://user:pass@host/db
EOF

# docker-compose.yml 中引用
env_file:
  - .env
```

### 2. 使用数据卷持久化

```yaml
volumes:
  - sloan-data:/app/data
  - sloan-logs:/app/logs

volumes:
  sloan-data:
  sloan-logs:
```

### 3. 配置反向代理（Nginx）

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

### 4. 启用 HTTPS

```bash
# 使用 Let's Encrypt
certbot --nginx -d your-domain.com
```

## 🎓 学习资源

- [Docker 官方文档](https://docs.docker.com/)
- [Docker Compose 文档](https://docs.docker.com/compose/)
- [Flask 部署指南](https://flask.palletsprojects.com/en/latest/deploying/)
- [Vue 生产环境部署](https://vuejs.org/guide/best-practices/production-deployment.html)

## 📞 支持

如遇问题，请查看：
1. 容器日志：`docker compose logs -f`
2. 健康检查状态：`docker compose ps`
3. 网络连接：`docker network inspect sloan-toolkit_sloan-network`

## 📄 许可证

本项目遵循 MIT 许可证。
