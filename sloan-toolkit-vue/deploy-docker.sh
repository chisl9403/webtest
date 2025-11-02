#!/bin/bash

# ==========================================
# Sloan Toolkit - 一键部署脚本
# 支持 Mac / Linux / Windows (Git Bash)
# ==========================================

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检测操作系统
detect_os() {
    case "$(uname -s)" in
        Darwin*)
            OS="Mac"
            ;;
        Linux*)
            OS="Linux"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            OS="Windows"
            ;;
        *)
            OS="Unknown"
            ;;
    esac
    print_info "检测到操作系统: $OS"
}

# 检查 Docker 是否安装
check_docker() {
    print_info "检查 Docker 安装状态..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装!"
        print_info "请访问 https://www.docker.com/products/docker-desktop 下载安装"
        exit 1
    fi
    
    DOCKER_VERSION=$(docker --version)
    print_success "Docker 已安装: $DOCKER_VERSION"
    
    # 检查 Docker 守护进程是否运行
    if ! docker info &> /dev/null; then
        print_error "Docker 守护进程未运行!"
        print_info "请启动 Docker Desktop 或 Docker 服务"
        exit 1
    fi
    
    print_success "Docker 守护进程运行正常"
}

# 检查 Docker Compose
check_docker_compose() {
    print_info "检查 Docker Compose..."
    
    if docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version)
        print_success "Docker Compose 已安装: $COMPOSE_VERSION"
    else
        print_error "Docker Compose 未安装!"
        exit 1
    fi
}

# 检查端口占用
check_ports() {
    print_info "检查端口占用..."
    
    PORTS=(5000 3000)
    for PORT in "${PORTS[@]}"; do
        if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1 || netstat -an 2>/dev/null | grep ":$PORT " | grep LISTEN >/dev/null; then
            print_warning "端口 $PORT 已被占用"
            read -p "是否继续? (y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_error "部署已取消"
                exit 1
            fi
        else
            print_success "端口 $PORT 可用"
        fi
    done
}

# 清理旧容器
cleanup() {
    print_info "清理旧容器和镜像..."
    
    if docker compose ps | grep -q "sloan-toolkit"; then
        print_info "停止现有容器..."
        docker compose down
        print_success "容器已停止"
    fi
}

# 构建镜像
build_image() {
    print_info "开始构建 Docker 镜像..."
    print_warning "首次构建可能需要 5-10 分钟，请耐心等待..."
    
    if docker compose build --no-cache; then
        print_success "镜像构建成功!"
    else
        print_error "镜像构建失败!"
        exit 1
    fi
}

# 启动服务
start_services() {
    print_info "启动服务..."
    
    if docker compose up -d; then
        print_success "服务启动成功!"
    else
        print_error "服务启动失败!"
        docker compose logs
        exit 1
    fi
}

# 等待服务就绪
wait_for_service() {
    print_info "等待服务就绪..."
    
    MAX_RETRY=30
    RETRY=0
    
    while [ $RETRY -lt $MAX_RETRY ]; do
        if curl -s http://localhost:5000/health > /dev/null 2>&1; then
            print_success "服务已就绪!"
            return 0
        fi
        
        RETRY=$((RETRY+1))
        echo -n "."
        sleep 2
    done
    
    echo ""
    print_error "服务启动超时!"
    print_info "查看日志:"
    docker compose logs
    exit 1
}

# 显示服务信息
show_info() {
    echo ""
    echo "=========================================="
    print_success "🎉 部署完成!"
    echo "=========================================="
    echo ""
    echo -e "${BLUE}访问地址:${NC}"
    echo "  📊 后端 API:  http://localhost:5000"
    echo "  🌐 前端页面:  http://localhost:5000"
    echo "  📡 健康检查:  http://localhost:5000/health"
    echo ""
    echo -e "${BLUE}常用命令:${NC}"
    echo "  查看日志:     docker compose logs -f"
    echo "  查看状态:     docker compose ps"
    echo "  停止服务:     docker compose down"
    echo "  重启服务:     docker compose restart"
    echo ""
    echo -e "${BLUE}容器信息:${NC}"
    docker compose ps
    echo ""
    echo "=========================================="
}

# 主函数
main() {
    echo "=========================================="
    echo "  Sloan Toolkit - 一键部署脚本"
    echo "=========================================="
    echo ""
    
    # 检测环境
    detect_os
    check_docker
    check_docker_compose
    check_ports
    
    # 部署流程
    cleanup
    build_image
    start_services
    wait_for_service
    
    # 显示信息
    show_info
}

# 捕获错误
trap 'print_error "部署过程中出现错误! 退出码: $?"' ERR

# 执行主函数
main
