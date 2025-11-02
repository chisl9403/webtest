# 🚀 快速启动指南

## 一分钟上手

### 第一步：检查环境

```bash
./check-env.sh
```

### 第二步：选择部署方式

#### 🐳 方式A：Docker 部署（推荐）

```bash
./deploy-docker.sh
```

访问：http://localhost:5000

#### 💻 方式B：本地开发

```bash
# 1. 安装依赖
npm install
pip install -r requirements.txt

# 2. 配置文件
cp config.example.json config.json
# 编辑 config.json 添加天气 API Key

# 3. 启动服务
./start-auto.sh
```

访问：http://localhost:3000

## 常用命令

### Docker 相关

```bash
# 启动服务
docker compose up -d

# 查看日志
docker compose logs -f

# 停止服务
docker compose down

# 重启服务
docker compose restart

# 重新构建
docker compose build --no-cache
```

### 本地开发

```bash
# 启动服务
./start-auto.sh

# 停止服务
./stop-auto.sh

# 仅启动后端
./start-backend.sh

# 仅启动前端
npm run dev
```

## 故障排查

### 端口被占用

```bash
# Mac/Linux
lsof -i :5000
lsof -i :3000

# Windows
netstat -ano | findstr :5000
```

### Docker 问题

```bash
# 查看容器状态
docker compose ps

# 查看详细日志
docker compose logs sloan-toolkit

# 进入容器
docker compose exec sloan-toolkit sh
```

### Python 依赖问题

```bash
# 重新安装
pip install -r requirements.txt --force-reinstall
```

### 前端依赖问题

```bash
# 清理重装
rm -rf node_modules package-lock.json
npm install
```

## 文档导航

- 📖 [完整 README](./README.md) - 项目介绍和本地开发
- 🐳 [Docker 部署指南](./DOCKER_GUIDE.md) - 详细的 Docker 部署文档
- 📋 [部署配置总结](./DEPLOYMENT_SUMMARY.md) - 跨平台部署详细说明
- ⚙️ [配置指南](./CONFIG_GUIDE.md) - 配置文件说明

## 获取帮助

- GitHub Issues: https://github.com/chisl9403/webtest/issues
- 文档：查看上述文档链接
- 环境检查：`./check-env.sh`

---

⭐ 祝使用愉快！
