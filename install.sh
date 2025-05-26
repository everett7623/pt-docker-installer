#!/bin/bash

# PT Docker 一键安装脚本
# 作者: everett7623
# 版本: v1.0
# GitHub: https://github.com/everett7623/pt-docker-installer

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认配置
DEFAULT_INSTALL_PATH="/opt/docker"
DEFAULT_DOWNLOAD_PATH="/opt/downloads"
COMPOSE_FILE="docker-compose.yml"

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_blue() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# 检查系统环境
check_system() {
    log_info "检查系统环境..."
    
    # 检查是否为root用户
    if [[ $EUID -ne 0 ]]; then
        log_error "请使用root权限运行此脚本"
        exit 1
    fi
    
    # 检查系统类型
    if [[ ! -f /etc/os-release ]]; then
        log_error "无法识别系统类型"
        exit 1
    fi
    
    source /etc/os-release
    log_info "检测到系统: $PRETTY_NAME"
}

# 检查并安装Docker
install_docker() {
    if ! command -v docker &> /dev/null; then
        log_info "Docker未安装，开始安装Docker..."
        curl -fsSL https://get.docker.com | sh
        systemctl start docker
        systemctl enable docker
        log_info "Docker安装完成"
    else
        log_info "Docker已安装"
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_info "Docker Compose未安装，开始安装..."
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        log_info "Docker Compose安装完成"
    else
        log_info "Docker Compose已安装"
    fi
}

# 创建目录结构
create_directories() {
    log_info "创建目录结构..."
    
    # 创建主目录
    mkdir -p "$INSTALL_PATH"
    mkdir -p "$DOWNLOAD_PATH"
    
    # 创建应用配置目录
    mkdir -p "$INSTALL_PATH"/{qbittorrent,transmission,iyuuplus,moviepilot}
    mkdir -p "$INSTALL_PATH"/{emby,jellyfin,plex}
    
    # 设置权限
    chmod -R 777 "$INSTALL_PATH"
    chmod -R 777 "$DOWNLOAD_PATH"
    
    log_info "目录创建完成"
}

# 生成核心应用Docker Compose配置
generate_core_compose() {
    log_info "生成核心应用配置..."
    
    cat > "$INSTALL_PATH/$COMPOSE_FILE" << 'EOF'
version: '3.8'

services:
  qbittorrent:
    image: linuxserver/qbittorrent:4.6.7
    container_name: qbittorrent
    environment:
      - PUID=0
      - PGID=0
      - TZ=Asia/Shanghai
      - WEBUI_PORT=8080
    volumes:
      - ./qbittorrent/config:/config
      - DOWNLOAD_PATH_PLACEHOLDER:/downloads
    ports:
      - "8080:8080"
      - "6881:6881"
      - "6881:6881/udp"
    restart: unless-stopped
    networks:
      - pt-network

  transmission:
    image: linuxserver/transmission:4.0.5
    container_name: transmission
    environment:
      - PUID=0
      - PGID=0
      - TZ=Asia/Shanghai
      - USER=admin
      - PASS=adminadmin
    volumes:
      - ./transmission/config:/config
      - DOWNLOAD_PATH_PLACEHOLDER:/downloads
    ports:
      - "9091:9091"
      - "51413:51413"
      - "51413:51413/udp"
    restart: unless-stopped
    networks:
      - pt-network

  iyuuplus:
    image: iyuucn/iyuuplus-dev:latest
    container_name: iyuuplus
    stdin_open: true
    tty: true
    volumes:
      - ./iyuuplus/iyuu:/iyuu
      - ./iyuuplus/data:/data
      - ./qbittorrent/config/qBittorrent/BT_backup:/qb
      - ./transmission/config/torrents:/tr
    ports:
      - "8780:8780"
    restart: always
    networks:
      - pt-network

  moviepilot:
    image: jxxghp/moviepilot-v2:latest
    container_name: moviepilot
    stdin_open: true
    tty: true
    hostname: moviepilot
    volumes:
      - DOWNLOAD_PATH_PLACEHOLDER:/media
      - ./moviepilot/config:/config
      - ./moviepilot/core:/moviepilot/.cache/ms-playwright
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./qbittorrent/config/qBittorrent/BT_backup:/qb
      - ./transmission/config/torrents:/tr
    environment:
      - NGINX_PORT=3000
      - PORT=3001
      - PUID=0
      - PGID=0
      - UMASK=000
      - TZ=Asia/Shanghai
      - SUPERUSER=admin
    ports:
      - "3000:3000"
      - "3001:3001"
    restart: always
    networks:
      - pt-network

networks:
  pt-network:
    driver: bridge

EOF

    # 替换下载路径占位符
    sed -i "s|DOWNLOAD_PATH_PLACEHOLDER|$DOWNLOAD_PATH|g" "$INSTALL_PATH/$COMPOSE_FILE"
    
    log_info "核心应用配置生成完成"
}

# 添加媒体服务器配置
add_media_server() {
    local server=$1
    log_info "添加 $server 配置..."
    
    case $server in
        "emby")
            cat >> "$INSTALL_PATH/$COMPOSE_FILE" << EOF

  emby:
    image: emby/embyserver:latest
    container_name: emby
    environment:
      - PUID=0
      - PGID=0
      - TZ=Asia/Shanghai
    volumes:
      - ./emby/config:/config
      - $DOWNLOAD_PATH:/media
    ports:
      - "8096:8096"
      - "8920:8920"
    devices:
      - /dev/dri:/dev/dri
    privileged: true
    restart: unless-stopped
    networks:
      - pt-network
EOF
            ;;
        "jellyfin")
            cat >> "$INSTALL_PATH/$COMPOSE_FILE" << EOF

  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    environment:
      - PUID=0
      - PGID=0
      - TZ=Asia/Shanghai
    volumes:
      - ./jellyfin/config:/config
      - ./jellyfin/cache:/cache
      - $DOWNLOAD_PATH:/media:ro
    ports:
      - "8096:8096"
      - "8920:8920"
      - "7359:7359/udp"
      - "1900:1900/udp"
    devices:
      - /dev/dri:/dev/dri
    restart: unless-stopped
    networks:
      - pt-network
EOF
            mkdir -p "$INSTALL_PATH/jellyfin"
            ;;
        "plex")
            cat >> "$INSTALL_PATH/$COMPOSE_FILE" << EOF

  plex:
    image: plexinc/pms-docker:latest
    container_name: plex
    environment:
      - PUID=0
      - PGID=0
      - TZ=Asia/Shanghai
      - PLEX_CLAIM=
    volumes:
      - ./plex/config:/config
      - ./plex/transcode:/transcode
      - $DOWNLOAD_PATH:/media:ro
    ports:
      - "32400:32400"
    devices:
      - /dev/dri:/dev/dri
    restart: unless-stopped
    networks:
      - pt-network
EOF
            mkdir -p "$INSTALL_PATH/plex"
            ;;
    esac
}

# 显示媒体服务器选择菜单
show_media_server_menu() {
    echo ""
    echo "========================================"
    echo "        选择媒体服务器 (可多选)"
    echo "========================================"
    echo "1. Emby (功能强大，付费解锁高级功能)"
    echo "2. Jellyfin (完全免费开源)"
    echo "3. Plex (免费基础功能，付费高级功能)"
    echo "4. 跳过媒体服务器安装"
    echo "========================================"
    
    read -p "请输入选择 (用空格分隔多个选项，如: 1 2): " choices
    
    for choice in $choices; do
        case $choice in
            1) add_media_server "emby" ;;
            2) add_media_server "jellyfin" ;;
            3) add_media_server "plex" ;;
            4) log_info "跳过媒体服务器安装" ;;
            *) log_warn "无效选择: $choice" ;;
        esac
    done
}

# 启动服务
start_services() {
    log_info "启动Docker服务..."
    cd "$INSTALL_PATH"
    docker-compose pull
    docker-compose up -d
    
    log_info "等待服务启动..."
    sleep 10
    
    # 检查服务状态
    if docker-compose ps | grep -q "Up"; then
        log_info "服务启动成功！"
        show_access_info
    else
        log_error "部分服务启动失败，请检查日志"
        docker-compose logs
    fi
}

# 显示访问信息
show_access_info() {
    local server_ip=$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP")
    
    echo ""
    echo "========================================"
    echo "        安装完成！访问信息"
    echo "========================================"
    echo "🔥 核心应用:"
    echo "   qBittorrent:  http://$server_ip:8080"
    echo "   Transmission: http://$server_ip:9091 (admin/adminadmin)"
    echo "   IYUU Plus:    http://$server_ip:8780"
    echo "   MoviePilot:   http://$server_ip:3000"
    echo ""
    
    # 检查是否安装了媒体服务器
    if docker-compose ps | grep -q "emby"; then
        echo "📺 Emby:         http://$server_ip:8096"
    fi
    if docker-compose ps | grep -q "jellyfin"; then
        echo "📺 Jellyfin:     http://$server_ip:8096"
    fi
    if docker-compose ps | grep -q "plex"; then
        echo "📺 Plex:         http://$server_ip:32400/web"
    fi
    
    echo ""
    echo "📁 下载目录: $DOWNLOAD_PATH"
    echo "🔧 配置目录: $INSTALL_PATH"
    echo ""
    echo "⚠️  首次使用建议:"
    echo "   1. 修改各应用的默认密码"
    echo "   2. 配置下载器连接信息"
    echo "   3. 设置媒体库路径为 /media"
    echo "========================================"
}

# 显示主菜单
show_main_menu() {
    clear
    echo "========================================"
    echo "    PT Docker 一键安装脚本 v1.0"
    echo "    作者: everett7623"
    echo "========================================"
    echo "1. 安装PT核心套件 (推荐新手)"
    echo "   - qBittorrent + Transmission"
    echo "   - IYUU Plus + MoviePilot"
    echo "   - 可选媒体服务器"
    echo ""
    echo "2. 自定义安装路径"
    echo "3. 查看系统信息"
    echo "4. 退出"
    echo "========================================"
}

# 自定义安装路径
customize_paths() {
    echo ""
    echo "当前配置:"
    echo "安装路径: $INSTALL_PATH"
    echo "下载路径: $DOWNLOAD_PATH"
    echo ""
    
    read -p "请输入Docker安装路径 (回车使用默认 $DEFAULT_INSTALL_PATH): " custom_install
    read -p "请输入下载目录路径 (回车使用默认 $DEFAULT_DOWNLOAD_PATH): " custom_download
    
    INSTALL_PATH=${custom_install:-$DEFAULT_INSTALL_PATH}
    DOWNLOAD_PATH=${custom_download:-$DEFAULT_DOWNLOAD_PATH}
    
    log_info "路径已更新:"
    log_info "安装路径: $INSTALL_PATH"
    log_info "下载路径: $DOWNLOAD_PATH"
}

# 显示系统信息
show_system_info() {
    echo ""
    echo "========================================"
    echo "           系统信息"
    echo "========================================"
    echo "系统: $(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "内核: $(uname -r)"
    echo "架构: $(uname -m)"
    echo "内存: $(free -h | grep Mem | awk '{print $2}')"
    echo "磁盘: $(df -h / | tail -1 | awk '{print $2 " (已用: " $3 ")"}')"
    echo "Docker: $(docker --version 2>/dev/null || echo "未安装")"
    echo "Docker Compose: $(docker-compose --version 2>/dev/null || echo "未安装")"
    echo "========================================"
    read -p "按回车键返回主菜单..."
}

# 主函数
main() {
    # 初始化路径
    INSTALL_PATH="$DEFAULT_INSTALL_PATH"
    DOWNLOAD_PATH="$DEFAULT_DOWNLOAD_PATH"
    
    while true; do
        show_main_menu
        read -p "请选择操作: " choice
        
        case $choice in
            1)
                check_system
                install_docker
                show_media_server_menu
                create_directories
                generate_core_compose
                start_services
                read -p "按回车键返回主菜单..."
                ;;
            2)
                customize_paths
                ;;
            3)
                show_system_info
                ;;
            4)
                log_info "感谢使用PT Docker安装脚本！"
                exit 0
                ;;
            *)
                log_warn "无效选择，请重新输入"
                sleep 2
                ;;
        esac
    done
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
