#!/bin/bash

# PT Docker Installer 容器入口点脚本
# 提供容器化的安装和管理功能

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 显示横幅
show_banner() {
    echo -e "${BLUE}"
    echo "████████████████████████████████████████"
    echo "█ PT Docker Installer Container Mode █"
    echo "█ 作者: everett7623                   █"
    echo "█ 版本: $(cat version.txt)                        █"
    echo "████████████████████████████████████████"
    echo -e "${NC}"
}

# 显示帮助信息
show_help() {
    cat << 'EOF'
PT Docker Installer - 容器化版本

用法: docker run [OPTIONS] pt-docker-installer [COMMAND] [ARGS...]

命令:
  install              运行主安装脚本
  advanced             运行高级安装脚本
  core-apps            安装核心应用
  media-servers        配置媒体服务器
  utils                运行工具脚本
  shell                进入交互式Shell
  version              显示版本信息
  help                 显示帮助信息

示例:
  # 交互式安装
  docker run -it --rm pt-docker-installer install

  # 进入Shell模式
  docker run -it --rm pt-docker-installer shell

  # 运行工具命令
  docker run --rm pt-docker-installer utils test-system

挂载建议:
  -v /opt/docker:/opt/docker        # 配置目录
  -v /opt/downloads:/opt/downloads   # 下载目录
  -v /var/run/docker.sock:/var/run/docker.sock  # Docker套接字

环境变量:
  INSTALL_PATH         Docker安装路径 (默认: /opt/docker)
  DOWNLOAD_PATH        下载路径 (默认: /opt/downloads)
  LOG_LEVEL           日志级别 (DEBUG/INFO/WARN/ERROR)
EOF
}

# 检查Docker套接字
check_docker_socket() {
    if [ ! -S "/var/run/docker.sock" ]; then
        log_warn "Docker套接字未挂载，某些功能可能无法使用"
        log_info "建议添加: -v /var/run/docker.sock:/var/run/docker.sock"
        return 1
    fi
    return 0
}

# 检查目录挂载
check_mounts() {
    local install_path=${INSTALL_PATH:-/opt/docker}
    local download_path=${DOWNLOAD_PATH:-/opt/downloads}
    
    if [ ! -d "$install_path" ] || [ ! -w "$install_path" ]; then
        log_warn "安装目录不可写: $install_path"
        log_info "建议添加: -v /opt/docker:/opt/docker"
    fi
    
    if [ ! -d "$download_path" ] || [ ! -w "$download_path" ]; then
        log_warn "下载目录不可写: $download_path"
        log_info "建议添加: -v /opt/downloads:/opt/downloads"
    fi
}

# 设置权限
setup_permissions() {
    local install_path=${INSTALL_PATH:-/opt/docker}
    local download_path=${DOWNLOAD_PATH:-/opt/downloads}
    
    # 尝试创建目录
    mkdir -p "$install_path" "$download_path" 2>/dev/null || true
    
    # 检查权限
    if [ -w "$install_path" ] && [ -w "$download_path" ]; then
        log_info "目录权限检查通过"
        return 0
    else
        log_error "目录权限不足，请检查挂载配置"
        return 1
    fi
}

# 初始化环境
init_environment() {
    log_info "初始化容器环境..."
    
    # 设置默认环境变量
    export INSTALL_PATH=${INSTALL_PATH:-/opt/docker}
    export DOWNLOAD_PATH=${DOWNLOAD_PATH:-/opt/downloads}
    export LOG_LEVEL=${LOG_LEVEL:-INFO}
    export TZ=${TZ:-Asia/Shanghai}
    
    # 检查挂载和权限
    check_docker_socket
    check_mounts
    setup_permissions
    
    log_info "环境初始化完成"
}

# 主函数
main() {
    local command=${1:-help}
    
    # 显示横幅
    if [ "$command" != "shell" ]; then
        show_banner
    fi
    
    # 初始化环境
    init_environment
    
    case $command in
        "install")
            log_info "启动主安装脚本..."
            exec ./install.sh "${@:2}"
            ;;
        "advanced")
            log_info "启动高级安装脚本..."
            exec ./scripts/advanced-installer.sh "${@:2}"
            ;;
        "core-apps")
            log_info "启动核心应用安装..."
            exec ./scripts/core-apps.sh "${@:2}"
            ;;
        "media-servers")
            log_info "启动媒体服务器配置..."
            exec ./scripts/media-servers.sh "${@:2}"
            ;;
        "utils")
            exec ./scripts/utils.sh "${@:2}"
            ;;
        "docker-utils")
            exec ./scripts/docker-utils.sh "${@:2}"
            ;;
        "shell"|"bash")
            log_info "进入交互式Shell..."
            exec /bin/bash
            ;;
        "version"|"--version")
            echo "PT Docker Installer $(cat version.txt)"
            echo "Container Mode - $(date)"
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            log_error "未知命令: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 信号处理
trap 'log_info "收到退出信号，正在清理..."; exit 0' SIGTERM SIGINT

# 运行主函数
main "$@"
