#!/bin/bash

# PT Docker 一键安装脚本 v1.0
# 专为PT用户设计的Docker应用快速部署工具
# 作者: everett7623
# GitHub: https://github.com/everett7623/pt-docker-installer
# 许可: MIT License

set -e

# 脚本信息
SCRIPT_VERSION="1.0.0"
SCRIPT_NAME="PT Docker Installer"
GITHUB_REPO="everett7623/pt-docker-installer"
SCRIPT_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/main/install.sh"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# 默认配置
DEFAULT_INSTALL_PATH="/opt/docker"
DEFAULT_DOWNLOAD_PATH="/opt/downloads"
DEFAULT_BACKUP_PATH="/opt/backups"
COMPOSE_FILE="docker-compose.yml"
LOG_FILE="/var/log/pt-docker-install.log"

# 全局变量
INSTALL_PATH=""
DOWNLOAD_PATH=""
BACKUP_PATH=""
SELECTED_MEDIA_SERVERS=()
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 日志函数
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
    log_message "INFO" "$1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    log_message "WARN" "$1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    log_message "ERROR" "$1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    log_message "SUCCESS" "$1"
}

log_debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $1"
        log_message "DEBUG" "$1"
    fi
}

# 显示横幅
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
 ____  _____   ____             _             
|  _ \|_   _| |  _ \  ___   ___| | _____ _ __ 
| |_) | | |   | | | |/ _ \ / __| |/ / _ \ '__|
|  __/  | |   | |_| | (_) | (__|   <  __/ |   
|_|     |_|   |____/ \___/ \___|_|\_\___|_|   
                                             
 ___           _        _ _                  
|_ _|_ __  ___| |_ __ _| | | ___ _ __         
 | || '_ \/ __| __/ _` | | |/ _ \ '__|        
 | || | | \__ \ || (_| | | |  __/ |           
|___|_| |_|___/\__\__,_|_|_|\___|_|           
                                             
EOF
    echo -e "${NC}"
    echo -e "${WHITE}${SCRIPT_NAME} v${SCRIPT_VERSION}${NC}"
    echo -e "${BLUE}专为PT用户设计的Docker应用一键安装工具${NC}"
    echo -e "${BLUE}作者: everett7623 | 许可: MIT License${NC}"
    echo -e "${CYAN}======================================${NC}"
    echo ""
}

# 显示帮助信息
show_help() {
    cat << EOF
用法: $0 [选项]

选项:
  -h, --help              显示帮助信息
  -v, --version           显示版本信息
  --install-path PATH     设置安装路径 (默认: $DEFAULT_INSTALL_PATH)
  --download-path PATH    设置下载路径 (默认: $DEFAULT_DOWNLOAD_PATH)
  --backup-path PATH      设置备份路径 (默认: $DEFAULT_BACKUP_PATH)
  --skip-docker           跳过Docker安装
  --skip-media            跳过媒体服务器安装
  --media SERVERS         指定媒体服务器 (emby,jellyfin,plex)
  --debug                 启用调试模式
  --dry-run               干运行模式 (不实际执行)
  --uninstall             卸载PT Docker环境
  --update                更新脚本到最新版本

示例:
  $0                                    # 交互式安装
  $0 --media emby,jellyfin             # 安装指定媒体服务器
  $0 --install-path /home/docker       # 自定义安装路径
  $0 --debug                           # 调试模式安装
  $0 --uninstall                       # 卸载环境

更多信息: https://github.com/$GITHUB_REPO
EOF
}

# 显示版本信息
show_version() {
    echo "$SCRIPT_NAME v$SCRIPT_VERSION"
    echo "GitHub: https://github.com/$GITHUB_REPO"
    echo "License: MIT"
}

# 解析命令行参数
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            --install-path)
                INSTALL_PATH="$2"
                shift 2
                ;;
            --download-path)
                DOWNLOAD_PATH="$2"
                shift 2
                ;;
            --backup-path)
                BACKUP_PATH="$2"
                shift 2
                ;;
            --skip-docker)
                SKIP_DOCKER=1
                shift
                ;;
            --skip-media)
                SKIP_MEDIA=1
                shift
                ;;
            --media)
                IFS=',' read -ra SELECTED_MEDIA_SERVERS <<< "$2"
                shift 2
                ;;
            --debug)
                DEBUG=1
                shift
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --uninstall)
                UNINSTALL=1
                shift
                ;;
            --update)
                UPDATE_SCRIPT=1
                shift
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 检查依赖命令
check_dependencies() {
    local deps=("curl" "wget" "tar" "gzip")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_info "安装缺失的依赖: ${missing_deps[*]}"
        install_dependencies "${missing_deps[@]}"
    fi
}

# 安装依赖
install_dependencies() {
    local deps=("$@")
    
    if command -v apt-get &> /dev/null; then
        apt-get update
        apt-get install -y "${deps[@]}"
    elif command -v yum &> /dev/null; then
        yum install -y "${deps[@]}"
    elif command -v dnf &> /dev/null; then
        dnf install -y "${deps[@]}"
    else
        log_error "无法自动安装依赖，请手动安装: ${deps[*]}"
        exit 1
    fi
}

# 检查系统环境
check_system() {
    log_info "检查系统环境..."
    
    # 检查操作系统
    if [[ ! -f /etc/os-release ]]; then
        log_error "无法识别操作系统"
        exit 1
    fi
    
    source /etc/os-release
    log_info "检测到系统: $PRETTY_NAME"
    
    # 检查架构
    local arch=$(uname -m)
    case $arch in
        x86_64|amd64)
            log_info "系统架构: $arch ✓"
            ;;
        aarch64|arm64)
            log_info "系统架构: $arch ✓"
            ;;
        *)
            log_warn "未测试的系统架构: $arch"
            ;;
    esac
    
    # 检查内存
    local mem_gb=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$mem_gb" -lt 1 ]; then
        log_warn "系统内存不足1GB，可能影响性能"
    else
        log_info "系统内存: ${mem_gb}GB ✓"
    fi
    
    # 检查磁盘空间
    local disk_avail=$(df / | tail -1 | awk '{print $4}')
    local disk_avail_gb=$((disk_avail / 1024 / 1024))
    if [ "$disk_avail_gb" -lt 10 ]; then
        log_error "磁盘可用空间不足10GB"
        exit 1
    else
        log_info "磁盘可用空间: ${disk_avail_gb}GB ✓"
    fi
}

# 检查权限
check_permissions() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        log_info "请使用: sudo $0"
        exit 1
    fi
}

# 更新脚本
update_script() {
    log_info "正在更新脚本..."
    
    local temp_script="/tmp/install.sh.new"
    
    if curl -fsSL "$SCRIPT_URL" -o "$temp_script"; then
        chmod +x "$temp_script"
        mv "$temp_script" "$0"
        log_success "脚本已更新到最新版本"
        log_info "重新运行脚本..."
        exec "$0" "$@"
    else
        log_error "脚本更新失败"
        exit 1
    fi
}

# 加载工具函数
load_utils() {
    local utils_script="$SCRIPT_DIR/scripts/utils.sh"
    
    if [[ -f "$utils_script" ]]; then
        log_debug "加载工具函数: $utils_script"
        source "$utils_script"
    else
        log_debug "未找到工具函数文件，使用内置函数"
    fi
}

# 检查并安装Docker
install_docker() {
    if [[ "${SKIP_DOCKER:-0}" == "1" ]]; then
        log_info "跳过Docker安装"
        return 0
    fi
    
    if command -v docker &> /dev/null && docker info &> /dev/null; then
        log_info "Docker已安装并运行 ✓"
    else
        log_info "开始安装Docker..."
        if [[ "${DRY_RUN:-0}" == "1" ]]; then
            log_info "[DRY-RUN] 将执行: curl -fsSL https://get.docker.com | sh"
        else
            curl -fsSL https://get.docker.com | sh
            systemctl start docker
            systemctl enable docker
        fi
        log_success "Docker安装完成"
    fi
    
    # 安装Docker Compose
    if command -v docker-compose &> /dev/null; then
        log_info "Docker Compose已安装 ✓"
    else
        log_info "开始安装Docker Compose..."
        if [[ "${DRY_RUN:-0}" == "1" ]]; then
            log_info "[DRY-RUN] 将安装Docker Compose"
        else
            local compose_version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
            curl -L "https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            chmod +x /usr/local/bin/docker-compose
        fi
        log_success "Docker Compose安装完成"
    fi
}

# 设置路径
setup_paths() {
    INSTALL_PATH=${INSTALL_PATH:-$DEFAULT_INSTALL_PATH}
    DOWNLOAD_PATH=${DOWNLOAD_PATH:-$DEFAULT_DOWNLOAD_PATH}
    BACKUP_PATH=${BACKUP_PATH:-$DEFAULT_BACKUP_PATH}
    
    log_info "配置路径:"
    log_info "  安装路径: $INSTALL_PATH"
    log_info "  下载路径: $DOWNLOAD_PATH"
    log_info "  备份路径: $BACKUP_PATH"
    
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log_info "[DRY-RUN] 将创建目录结构"
        return 0
    fi
    
    # 创建目录
    mkdir -p "$INSTALL_PATH" "$DOWNLOAD_PATH" "$BACKUP_PATH"
    mkdir -p "$DOWNLOAD_PATH"/{movies,tv,music,anime,books,temp}
    
    # 设置权限
    chmod -R 755 "$INSTALL_PATH" "$DOWNLOAD_PATH" "$BACKUP_PATH"
    
    log_success "目录创建完成"
}

# 使用核心应用脚本
install_core_apps() {
    local core_script="$SCRIPT_DIR/scripts/core-apps.sh"
    
    if [[ -f "$core_script" ]]; then
        log_info "使用核心应用安装脚本..."
        if [[ "${DRY_RUN:-0}" == "1" ]]; then
            log_info "[DRY-RUN] 将执行: $core_script install $INSTALL_PATH $DOWNLOAD_PATH"
        else
            bash "$core_script" install "$INSTALL_PATH" "$DOWNLOAD_PATH"
        fi
    else
        log_info "未找到核心应用脚本，使用内置安装..."
        install_core_apps_builtin
    fi
}

# 内置核心应用安装
install_core_apps_builtin() {
    log_info "生成核心应用配置..."
    
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log_info "[DRY-RUN] 将生成Docker Compose配置"
        return 0
    fi
    
    # 生成Docker Compose配置
    cat > "$INSTALL_PATH/$COMPOSE_FILE" << EOF
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
      - $DOWNLOAD_PATH:/downloads
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
      - $DOWNLOAD_PATH:/downloads
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
      - $DOWNLOAD_PATH:/media
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
    ipam:
      config:
        - subnet: 172.20.0.0/16
EOF

    # 创建应用配置目录
    mkdir -p "$INSTALL_PATH"/{qbittorrent,transmission,iyuuplus,moviepilot}
    
    log_success "核心应用配置生成完成"
}

# 媒体服务器选择菜单
select_media_servers() {
    if [[ "${SKIP_MEDIA:-0}" == "1" ]]; then
        log_info "跳过媒体服务器安装"
        return 0
    fi
    
    # 如果已通过参数指定了媒体服务器
    if [ ${#SELECTED_MEDIA_SERVERS[@]} -gt 0 ]; then
        log_info "使用指定的媒体服务器: ${SELECTED_MEDIA_SERVERS[*]}"
        install_media_servers
        return 0
    fi
    
    # 交互式选择
    echo ""
    echo -e "${BLUE}========================================"
    echo -e "        选择媒体服务器 (可多选)"
    echo -e "========================================${NC}"
    echo -e "${GREEN}1.${NC} Emby - 功能强大，付费解锁高级功能"
    echo -e "${GREEN}2.${NC} Jellyfin - 完全免费开源"
    echo -e "${GREEN}3.${NC} Plex - 主流媒体服务器"
    echo -e "${GREEN}4.${NC} 跳过媒体服务器安装"
    echo -e "${BLUE}========================================${NC}"
    
    read -p "请输入选择 (用空格分隔多个选项，如: 1 2): " choices
    
    for choice in $choices; do
        case $choice in
            1) SELECTED_MEDIA_SERVERS+=("emby") ;;
            2) SELECTED_MEDIA_SERVERS+=("jellyfin") ;;
            3) SELECTED_MEDIA_SERVERS+=("plex") ;;
            4) 
                log_info "跳过媒体服务器安装"
                return 0
                ;;
            *) log_warn "无效选择: $choice" ;;
        esac
    done
    
    if [ ${#SELECTED_MEDIA_SERVERS[@]} -gt 0 ]; then
        install_media_servers
    fi
}

# 安装媒体服务器
install_media_servers() {
    local media_script="$SCRIPT_DIR/scripts/media-servers.sh"
    
    if [[ -f "$media_script" ]]; then
        log_info "使用媒体服务器安装脚本..."
        local servers=$(IFS=,; echo "${SELECTED_MEDIA_SERVERS[*]}")
        if [[ "${DRY_RUN:-0}" == "1" ]]; then
            log_info "[DRY-RUN] 将执行: $media_script batch $INSTALL_PATH $DOWNLOAD_PATH $servers"
        else
            bash "$media_script" batch "$INSTALL_PATH" "$DOWNLOAD_PATH" "$servers"
        fi
    else
        log_info "未找到媒体服务器脚本，使用内置安装..."
        install_media_servers_builtin
    fi
}

# 内置媒体服务器安装
install_media_servers_builtin() {
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log_info "[DRY-RUN] 将添加媒体服务器配置"
        return 0
    fi
    
    for server in "${SELECTED_MEDIA_SERVERS[@]}"; do
        case $server in
            "emby")
                log_info "添加Emby配置..."
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
    restart: unless-stopped
    networks:
      - pt-network
EOF
                mkdir -p "$INSTALL_PATH/emby"
                ;;
                
            "jellyfin")
                log_info "添加Jellyfin配置..."
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
    devices:
      - /dev/dri:/dev/dri
    restart: unless-stopped
    networks:
      - pt-network
EOF
                mkdir -p "$INSTALL_PATH/jellyfin"
                ;;
                
            "plex")
                log_info "添加Plex配置..."
                cat >> "$INSTALL_PATH/$COMPOSE_FILE" << EOF

  plex:
    image: plexinc/pms-docker:latest
    container_name: plex
    environment:
      - PUID=0
      - PGID=0
      - TZ=Asia/Shanghai
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
    done
}

# 启动服务
start_services() {
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log_info "[DRY-RUN] 将启动Docker服务"
        return 0
    fi
    
    log_info "启动Docker服务..."
    cd "$INSTALL_PATH"
    
    # 拉取镜像
    log_info "拉取Docker镜像..."
    docker-compose pull
    
    # 启动服务
    log_info "启动容器..."
    docker-compose up -d
    
    # 等待服务启动
    log_info "等待服务启动..."
    sleep 15
    
    # 检查服务状态
    check_services_status
}

# 检查服务状态
check_services_status() {
    local failed_services=()
    
    while IFS= read -r line; do
        if [[ $line == *"Exit"* || $line == *"Restarting"* ]]; then
            local service_name=$(echo "$line" | awk '{print $1}')
            failed_services+=("$service_name")
        fi
    done < <(docker-compose ps 2>/dev/null)
    
    if [ ${#failed_services[@]} -eq 0 ]; then
        log_success "所有服务启动成功！"
        show_access_info
    else
        log_error "以下服务启动失败: ${failed_services[*]}"
        for service in "${failed_services[@]}"; do
            echo -e "${RED}=== $service 错误日志 ===${NC}"
            docker-compose logs --tail 10 "$service"
        done
        return 1
    fi
}

# 显示访问信息
show_access_info() {
    local server_ip
    server_ip=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}' || echo "Your_Server_IP")
    
    echo ""
    echo -e "${CYAN}========================================"
    echo -e "        安装完成！访问信息"
    echo -e "========================================${NC}"
    echo -e "${GREEN}🔥 核心应用:${NC}"
    echo -e "   qBittorrent:  http://${server_ip}:8080"
    echo -e "   Transmission: http://${server_ip}:9091 (admin/adminadmin)"
    echo -e "   IYUU Plus:    http://${server_ip}:8780"
    echo -e "   MoviePilot:   http://${server_ip}:3000"
    echo ""
    
    # 显示媒体服务器信息
    if [ ${#SELECTED_MEDIA_SERVERS[@]} -gt 0 ]; then
        echo -e "${GREEN}📺 媒体服务器:${NC}"
        for server in "${SELECTED_MEDIA_SERVERS[@]}"; do
            case $server in
                "emby"|"jellyfin")
                    echo -e "   ${server^}:        http://${server_ip}:8096"
                    ;;
                "plex")
                    echo -e "   Plex:         http://${server_ip}:32400/web"
                    ;;
            esac
        done
        echo ""
    fi
    
    echo -e "${GREEN}📁 目录信息:${NC}"
    echo -e "   下载目录: $DOWNLOAD_PATH"
    echo -e "   配置目录: $INSTALL_PATH"
    echo -e "   备份目录: $BACKUP_PATH"
    echo ""
    echo -e "${YELLOW}⚠️  首次使用建议:${NC}"
    echo -e "   1. 修改各应用的默认密码"
    echo -e "   2. 配置下载器连接信息"
    echo -e "   3. 设置媒体库路径为 /media"
    echo -e "   4. 查看文档了解详细配置方法"
    echo ""
    echo -e "${BLUE}📚 更多信息:${NC}"
    echo -e "   项目地址: https://github.com/$GITHUB_REPO"
    echo -e "   使用文档: https://github.com/$GITHUB_REPO/blob/main/docs/"
    echo -e "   问题反馈: https://github.com/$GITHUB_REPO/issues"
    echo -e "${CYAN}========================================${NC}"
}

# 卸载功能
uninstall_pt_docker() {
    log_warn "准备卸载PT Docker环境..."
    
    if [[ ! -d "$INSTALL_PATH" ]]; then
        log_info "未找到安装目录，可能已经卸载"
        return 0
    fi
    
    echo -e "${RED}警告: 此操作将删除所有PT Docker应用及其配置！${NC}"
    read -p "确认卸载? (输入 'yes' 确认): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        log_info "卸载操作已取消"
        return 0
    fi
    
    # 停止并删除容器
    log_info "停止并删除容器..."
    cd "$INSTALL_PATH"
    docker-compose down -v 2>/dev/null || true
    
    # 删除镜像
    log_info "删除相关镜像..."
    docker rmi $(docker images | grep -E "(qbittorrent|transmission|iyuuplus|moviepilot|emby|jellyfin|plex)" | awk '{print $3}') 2>/dev/null || true
    
    # 备份配置
    if [[ -d "$INSTALL_PATH" ]]; then
        local backup_name="pt-docker-backup-$(date +%Y%m%d_%H%M%S)"
        log_info "备份配置到: $BACKUP_PATH/$backup_name.tar.gz"
        tar -czf "$BACKUP_PATH/$backup_name.tar.gz" -C "$(dirname "$INSTALL_PATH")" "$(basename "$INSTALL_PATH")"
    fi
    
    # 删除安装目录
    log_info "删除安装目录..."
    rm -rf "$INSTALL_PATH"
    
    log_success "PT Docker环境卸载完成"
    log_info "配置已备份到: $BACKUP_PATH"
}

# 创建快捷命令
create_shortcuts() {
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log_info "[DRY-RUN] 将创建快捷命令"
        return 0
    fi
    
    log_info "创建管理快捷命令..."
    
    # 创建pt-docker命令
    cat > /usr/local/bin/pt-docker << EOF
#!/bin/bash
# PT Docker 管理命令

INSTALL_PATH="$INSTALL_PATH"
SCRIPT_DIR="$SCRIPT_DIR"

case \$1 in
    "status"|"ps")
        cd "\$INSTALL_PATH" && docker-compose ps
        ;;
    "logs")
        cd "\$INSTALL_PATH" && docker-compose logs \${@:2}
        ;;
    "restart")
        cd "\$INSTALL_PATH" && docker-compose restart \${@:2}
        ;;
    "stop")
        cd "\$INSTALL_PATH" && docker-compose stop \${@:2}
        ;;
    "start")
        cd "\$INSTALL_PATH" && docker-compose start \${@:2}
        ;;
    "update")
        cd "\$INSTALL_PATH" && docker-compose pull && docker-compose up -d
        ;;
    "backup")
        if [[ -f "\$SCRIPT_DIR/scripts/docker-utils.sh" ]]; then
            bash "\$SCRIPT_DIR/scripts/docker-utils.sh" backup
        else
            echo "备份脚本未找到"
        fi
        ;;
    "shell")
        cd "\$INSTALL_PATH" && bash
        ;;
    *)
        echo "PT Docker 管理工具"
        echo ""
        echo "用法: pt-docker <命令> [参数]"
        echo ""
        echo "命令:"
        echo "  status, ps        显示服务状态"
        echo "  logs [服务名]     查看日志"
        echo "  restart [服务名]  重启服务"
        echo "  stop [服务名]     停止服务"
        echo "  start [服务名]    启动服务"
        echo "  update           更新所有服务"
        echo "  backup           备份配置"
        echo "  shell            进入管理目录"
        echo ""
        echo "示例:"
        echo "  pt-docker status              # 查看所有服务状态"
        echo "  pt-docker logs qbittorrent    # 查看qB日志"
        echo "  pt-docker restart moviepilot # 重启MP"
        ;;
esac
EOF
    
    chmod +x /usr/local/bin/pt-docker
    log_success "快捷命令创建完成，可使用 'pt-docker' 命令管理"
}

# 生成配置文件
generate_config_files() {
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log_info "[DRY-RUN] 将生成配置文件"
        return 0
    fi
    
    log_info "生成配置文件..."
    
    # 生成环境变量文件
    cat > "$INSTALL_PATH/.env" << EOF
# PT Docker 环境变量配置
# 生成时间: $(date)

# 基础配置
TZ=Asia/Shanghai
PUID=0
PGID=0
UMASK=000

# 路径配置
DOCKER_ROOT=$INSTALL_PATH
DOWNLOAD_ROOT=$DOWNLOAD_PATH
BACKUP_ROOT=$BACKUP_PATH

# 网络配置
SERVER_IP=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

# 应用端口
QB_PORT=8080
TR_PORT=9091
IYUU_PORT=8780
MP_PORT=3000

# 日志配置
LOG_LEVEL=INFO
LOG_MAX_SIZE=100
LOG_RETENTION_DAYS=30
EOF
    
    # 生成README文件
    cat > "$INSTALL_PATH/README.md" << EOF
# PT Docker 安装信息

## 安装信息
- 安装时间: $(date)
- 安装路径: $INSTALL_PATH
- 下载路径: $DOWNLOAD_PATH
- 脚本版本: $SCRIPT_VERSION

## 核心服务
- qBittorrent: http://$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || echo "YOUR_IP"):8080
- Transmission: http://$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || echo "YOUR_IP"):9091
- IYUU Plus: http://$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || echo "YOUR_IP"):8780
- MoviePilot: http://$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || echo "YOUR_IP"):3000

## 媒体服务器
EOF
    
    for server in "${SELECTED_MEDIA_SERVERS[@]}"; do
        case $server in
            "emby"|"jellyfin")
                echo "- ${server^}: http://$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || echo "YOUR_IP"):8096" >> "$INSTALL_PATH/README.md"
                ;;
            "plex")
                echo "- Plex: http://$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || echo "YOUR_IP"):32400/web" >> "$INSTALL_PATH/README.md"
                ;;
        esac
    done
    
    cat >> "$INSTALL_PATH/README.md" << EOF

## 常用命令
\`\`\`bash
# 查看服务状态
pt-docker status

# 查看日志
pt-docker logs qbittorrent

# 重启服务
pt-docker restart moviepilot

# 更新所有服务
pt-docker update
\`\`\`

## 配置说明
- 所有配置文件位于各应用的config目录下
- 下载文件保存在 $DOWNLOAD_PATH 目录
- 媒体库路径设置为 /media

## 获取帮助
- 项目地址: https://github.com/$GITHUB_REPO
- 问题反馈: https://github.com/$GITHUB_REPO/issues
- 使用文档: https://github.com/$GITHUB_REPO/blob/main/docs/
EOF
    
    log_success "配置文件生成完成"
}

# 设置定时任务
setup_cron_jobs() {
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log_info "[DRY-RUN] 将设置定时任务"
        return 0
    fi
    
    log_info "设置定时任务..."
    
    # 检查是否已存在相关定时任务
    if crontab -l 2>/dev/null | grep -q "pt-docker"; then
        log_info "定时任务已存在，跳过设置"
        return 0
    fi
    
    # 创建定时任务
    (crontab -l 2>/dev/null; cat << 'EOF'
# PT Docker 自动维护任务
# 每天凌晨2点备份配置
0 2 * * * /usr/local/bin/pt-docker backup >/dev/null 2>&1

# 每周日凌晨3点清理Docker
0 3 * * 0 docker system prune -f >/dev/null 2>&1

# 每小时检查服务健康状态
0 * * * * cd /opt/docker && docker-compose ps | grep -q "Exit" && docker-compose up -d >/dev/null 2>&1
EOF
) | crontab -
    
    log_success "定时任务设置完成"
}

# 主安装流程
main_install() {
    log_info "开始PT Docker安装流程..."
    
    # 1. 系统检查
    check_system
    check_dependencies
    
    # 2. 设置路径
    setup_paths
    
    # 3. 安装Docker
    install_docker
    
    # 4. 安装核心应用
    install_core_apps
    
    # 5. 选择媒体服务器
    select_media_servers
    
    # 6. 启动服务
    start_services
    
    # 7. 生成配置
    generate_config_files
    
    # 8. 创建快捷命令
    create_shortcuts
    
    # 9. 设置定时任务
    setup_cron_jobs
    
    log_success "PT Docker安装完成！"
}

# 主函数
main() {
    # 解析命令行参数
    parse_arguments "$@"
    
    # 特殊操作处理
    if [[ "${UPDATE_SCRIPT:-0}" == "1" ]]; then
        update_script "$@"
        exit 0
    fi
    
    if [[ "${UNINSTALL:-0}" == "1" ]]; then
        setup_paths  # 需要路径信息
        uninstall_pt_docker
        exit 0
    fi
    
    # 显示横幅
    show_banner
    
    # 检查权限
    check_permissions
    
    # 创建日志目录
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # 记录开始
    log_info "==================== 安装开始 ===================="
    log_info "脚本版本: $SCRIPT_VERSION"
    log_info "执行用户: $(whoami)"
    log_info "系统信息: $(uname -a)"
    log_info "执行参数: $*"
    
    # 加载工具函数
    load_utils
    
    # 执行主安装流程
    if main_install; then
        log_info "==================== 安装成功 ===================="
        
        # 发送成功通知
        if command -v curl &>/dev/null && [[ -n "${WEBHOOK_URL:-}" ]]; then
            curl -s -X POST "$WEBHOOK_URL" \
                -H "Content-Type: application/json" \
                -d "{\"text\":\"PT Docker安装成功 - $(hostname) - $(date)\"}" \
                >/dev/null 2>&1 || true
        fi
        
        exit 0
    else
        log_error "==================== 安装失败 ===================="
        
        # 发送失败通知
        if command -v curl &>/dev/null && [[ -n "${WEBHOOK_URL:-}" ]]; then
            curl -s -X POST "$WEBHOOK_URL" \
                -H "Content-Type: application/json" \
                -d "{\"text\":\"PT Docker安装失败 - $(hostname) - $(date)\"}" \
                >/dev/null 2>&1 || true
        fi
        
        exit 1
    fi
}

# 信号处理
cleanup() {
    log_warn "收到中断信号，正在清理..."
    
    # 停止可能正在运行的Docker操作
    if [[ -d "$INSTALL_PATH" ]] && [[ -f "$INSTALL_PATH/$COMPOSE_FILE" ]]; then
        cd "$INSTALL_PATH"
        docker-compose down 2>/dev/null || true
    fi
    
    log_info "清理完成"
    exit 130
}

# 设置信号处理
trap cleanup SIGINT SIGTERM

# 错误处理
set -eE
trap 'log_error "脚本执行出错，行号: $LINENO，命令: $BASH_COMMAND"' ERR

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
