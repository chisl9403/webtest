#!/bin/bash

# ==========================================
# 环境检查脚本
# 检查所有必要的依赖是否已安装
# ==========================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "  Sloan Toolkit - 环境检查"
echo "=========================================="
echo ""

# 检测操作系统
echo -e "${BLUE}[1/8] 检测操作系统...${NC}"
case "$(uname -s)" in
    Darwin*)
        OS="Mac"
        echo -e "${GREEN}✓${NC} macOS"
        ;;
    Linux*)
        OS="Linux"
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            echo -e "${GREEN}✓${NC} $NAME $VERSION"
        else
            echo -e "${GREEN}✓${NC} Linux"
        fi
        ;;
    CYGWIN*|MINGW*|MSYS*)
        OS="Windows"
        echo -e "${GREEN}✓${NC} Windows (Git Bash)"
        ;;
    *)
        OS="Unknown"
        echo -e "${YELLOW}?${NC} 未知操作系统"
        ;;
esac

# 检查 Node.js
echo ""
echo -e "${BLUE}[2/8] 检查 Node.js...${NC}"
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    REQUIRED_VERSION="v16.0.0"
    if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$NODE_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
        echo -e "${GREEN}✓${NC} Node.js $NODE_VERSION (满足要求 >= 16.x)"
    else
        echo -e "${YELLOW}!${NC} Node.js $NODE_VERSION (建议升级到 >= 16.x)"
    fi
else
    echo -e "${RED}✗${NC} Node.js 未安装"
    echo "  请访问: https://nodejs.org/"
fi

# 检查 npm
echo ""
echo -e "${BLUE}[3/8] 检查 npm...${NC}"
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    echo -e "${GREEN}✓${NC} npm $NPM_VERSION"
else
    echo -e "${RED}✗${NC} npm 未安装"
fi

# 检查 Python
echo ""
echo -e "${BLUE}[4/8] 检查 Python...${NC}"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo -e "${GREEN}✓${NC} $PYTHON_VERSION"
    
    # 检查版本是否 >= 3.9
    PYTHON_VER=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
    REQUIRED_PY_VERSION="3.9"
    if [ "$(printf '%s\n' "$REQUIRED_PY_VERSION" "$PYTHON_VER" | sort -V | head -n1)" = "$REQUIRED_PY_VERSION" ]; then
        echo -e "${GREEN}✓${NC} Python 版本满足要求 (>= 3.9)"
    else
        echo -e "${YELLOW}!${NC} Python 版本建议升级到 >= 3.9"
    fi
elif command -v python &> /dev/null; then
    PYTHON_VERSION=$(python --version)
    echo -e "${YELLOW}!${NC} $PYTHON_VERSION (建议使用 Python 3)"
else
    echo -e "${RED}✗${NC} Python 未安装"
    echo "  请访问: https://www.python.org/"
fi

# 检查 pip
echo ""
echo -e "${BLUE}[5/8] 检查 pip...${NC}"
if command -v pip3 &> /dev/null; then
    PIP_VERSION=$(pip3 --version)
    echo -e "${GREEN}✓${NC} $PIP_VERSION"
elif command -v pip &> /dev/null; then
    PIP_VERSION=$(pip --version)
    echo -e "${GREEN}✓${NC} $PIP_VERSION"
else
    echo -e "${RED}✗${NC} pip 未安装"
fi

# 检查 Docker
echo ""
echo -e "${BLUE}[6/8] 检查 Docker...${NC}"
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    echo -e "${GREEN}✓${NC} $DOCKER_VERSION"
    
    # 检查 Docker 守护进程
    if docker info &> /dev/null; then
        echo -e "${GREEN}✓${NC} Docker 守护进程运行正常"
    else
        echo -e "${YELLOW}!${NC} Docker 守护进程未运行"
        echo "  请启动 Docker Desktop 或 Docker 服务"
    fi
else
    echo -e "${YELLOW}!${NC} Docker 未安装 (可选，用于容器化部署)"
    echo "  下载: https://www.docker.com/products/docker-desktop"
fi

# 检查 Docker Compose
echo ""
echo -e "${BLUE}[7/8] 检查 Docker Compose...${NC}"
if docker compose version &> /dev/null 2>&1; then
    COMPOSE_VERSION=$(docker compose version)
    echo -e "${GREEN}✓${NC} $COMPOSE_VERSION"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version)
    echo -e "${YELLOW}!${NC} $COMPOSE_VERSION (建议升级到 Docker Compose V2)"
else
    echo -e "${YELLOW}!${NC} Docker Compose 未安装 (可选)"
fi

# 检查 Git
echo ""
echo -e "${BLUE}[8/8] 检查 Git...${NC}"
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version)
    echo -e "${GREEN}✓${NC} $GIT_VERSION"
else
    echo -e "${YELLOW}!${NC} Git 未安装 (建议安装)"
fi

# 总结
echo ""
echo "=========================================="
echo "  环境检查完成"
echo "=========================================="
echo ""

# 必需依赖检查
REQUIRED_OK=true

if ! command -v node &> /dev/null; then
    REQUIRED_OK=false
fi

if ! command -v npm &> /dev/null; then
    REQUIRED_OK=false
fi

if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
    REQUIRED_OK=false
fi

if ! command -v pip3 &> /dev/null && ! command -v pip &> /dev/null; then
    REQUIRED_OK=false
fi

if [ "$REQUIRED_OK" = true ]; then
    echo -e "${GREEN}✓${NC} 所有必需依赖已安装"
    echo ""
    echo "你可以使用以下方式部署："
    echo ""
    echo "  1. 本地开发模式："
    echo "     ./start-auto.sh"
    echo ""
    
    if command -v docker &> /dev/null && docker info &> /dev/null 2>&1; then
        echo "  2. Docker 容器化部署（推荐）："
        echo "     ./deploy-docker.sh"
        echo ""
    else
        echo "  2. Docker 容器化部署："
        echo "     安装 Docker 后运行: ./deploy-docker.sh"
        echo ""
    fi
else
    echo -e "${RED}✗${NC} 缺少必需依赖，请先安装："
    echo ""
    
    if ! command -v node &> /dev/null; then
        echo "  • Node.js: https://nodejs.org/"
    fi
    
    if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
        echo "  • Python: https://www.python.org/"
    fi
    
    echo ""
fi

echo "详细文档："
echo "  • 本地部署: ./README.md"
echo "  • Docker 部署: ./DOCKER_GUIDE.md"
echo ""
