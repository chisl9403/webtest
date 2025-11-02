# ==========================
# 前端构建阶段
# ==========================
FROM node:20-alpine AS frontend-builder

WORKDIR /app

# 复制前端依赖文件
COPY package*.json ./

# 安装前端依赖
RUN npm ci --only=production

# 复制前端源代码
COPY . .

# 构建前端应用
RUN npm run build

# ==========================
# Python 后端运行阶段
# ==========================
FROM python:3.11-slim

WORKDIR /app

# 安装系统依赖（matplotlib 需要）
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    libfreetype6-dev \
    libpng-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# 复制 Python 依赖文件
COPY requirements.txt .

# 安装 Python 依赖
RUN pip install --no-cache-dir -r requirements.txt

# 复制后端代码
COPY backend ./backend
COPY server.py .
COPY config*.json ./

# 从前端构建阶段复制构建产物
COPY --from=frontend-builder /app/dist ./dist

# 暴露端口
EXPOSE 5000 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:5000/health', timeout=5)"

# 设置环境变量
ENV PYTHONUNBUFFERED=1
ENV FLASK_ENV=production

# 启动后端服务
CMD ["python", "server.py"]
