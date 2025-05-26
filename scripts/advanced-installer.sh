#!/bin/bash

# PT Docker 高级安装脚本 - v2.0 预览版
# 支持更多应用的分类选择安装
# 作者: everett7623

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 默认配置
DEFAULT_INSTALL_PATH="/opt/docker"
DEFAULT_DOWNLOAD_PATH="/opt/downloads"
COMPOSE_FILE="docker-compose.yml"

# 应用分类定义
declare -A DOWNLOAD_APPS=(
    ["qbittorrent"]="qBittorrent - BT下载客户端"
    ["transmission"]="Transmission - BT下载客户端"
)

declare -A AUTOMATION_APPS=(
    ["iyuuplus"]="IYUU Plus - PT自动化管理"
    ["moviepilot"]="MoviePilot - 影视自动下载管理"
    ["sonarr"]="Sonarr - 电视剧自动化管理"
    ["radarr"]="Radarr - 电影自动化管理"
    ["lidarr"]="Lidarr - 音乐自动化管理"
    ["prowlarr"]="Prowlarr - 索引器管理"
    ["bazarr"]="Bazarr - 字幕自动化管理"
    ["autobrr"]="AutoBRR - 自动抓取工具"
    ["cross-seed"]="Cross-seed - 交叉做种工具"
    ["nastools"]="NAS-Tools - NAS自动化工具"
)

declare -A MEDIA_APPS=(
    ["emby"]="Emby - 功能强大的媒体服务器"
    ["jellyfin"]="Jellyfin - 开源媒体服务器"
    ["plex"]="Plex - 主流媒体服务器"
    ["navidrome"]="Navidrome - 音乐流媒体服务器"
    ["audiobookshelf"]="AudioBookshelf - 有声书管理"
)

declare -A SEARCH_APPS=(
    ["jackett"]="Jackett - BT搜索聚合器"
    ["prowlarr"]="Prowlarr - 索引器管理器"
    ["flaresolverr"]="FlareSolverr - CloudFlare绕过"
)

declare -A FILE_APPS=(
    ["filebrowser"]="FileBrowser - 网页文件管理器"
    ["alist"]="AList - 网盘文件列表程序"
    ["nextcloud"]="Nextcloud - 私有云存储"
    ["syncthing"]="Syncthing - 文件同步工具"
)

declare -A NETWORK_APPS=(
    ["nginx"]="Nginx - 反向代理服务器"
    ["frp"]="FRP - 内网穿透工具"
    ["wireguard"]="WireGuard - VPN工具"
    ["cloudflare-tunnel"]="Cloudflare Tunnel - 安全隧道"
)

declare -A MONITOR_APPS=(
    ["netdata"]="Netdata - 系统监控"
    ["portainer"]="Portainer - Docker管理"
    ["watchtower"]="Watchtower - 容器自动更新"
    ["librespeed"]="LibreSpeed - 网速测试"
)

declare -A SELECTED_APPS=()

# 日志函数
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_blue() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_purple() { echo -e "${PURPLE}[INFO]${NC} $1"; }

# 显示分类选择菜单
show_category_menu() {
    clear
    echo -e "${CYAN}========================================"
    echo -e "    PT Docker 高级安装脚本 v2.0"
    echo -e "    选择要安装的应用分类"
    echo -e "========================================${NC}"
    echo -e "${GREEN}1.${NC} 下载管理工具"
    echo -e "${GREEN}2.${NC} 自动化管理工具" 
    echo -e "${GREEN}3.${NC} 媒体服务器"
    echo -e "${GREEN}4.${NC} 搜索工具"
    echo -e "${GREEN}5.${NC} 文件管理工具"
    echo -e "${GREEN}6.${NC} 网络工具"
    echo -e "${GREEN}7.${NC} 监控管理工具"
    echo -e "${GREEN}8.${NC} 查看已选择应用"
    echo -e "${GREEN}9.${NC} 开始安装"
    echo -e "${GREEN}0.${NC} 返回主菜单"
    echo -e "${CYAN}========================================${NC}"
}

# 显示应用选择菜单
show_app_menu() {
    local category=$1
    local -n apps=$2
    local title=$3
    
    clear
    echo -e "${CYAN}========================================"
    echo -e "    $title"
    echo -e "========================================${NC}"
    
    local i=1
    local app_keys=()
    for app in "${!apps[@]}"; do
        app_keys+=("$app")
        local status=""
        if [[ -n "${SELECTED_APPS[$app]}" ]]; then
            status="${GREEN}[已选择]${NC}"
        fi
        echo -e "${GREEN}$i.${NC} ${apps[$app]} $status"
        ((i++))
    done
    
    echo -e "${GREEN}a.${NC} 全选"
    echo -e "${GREEN}c.${NC} 清空选择"
    echo -e "${GREEN}0.${NC} 返回分类菜单"
    echo -e "${CYAN}========================================${NC}"
    
    read -p "请选择应用 (多选用空格分隔，如: 1 2 3): " choices
    
    for choice in $choices; do
        if [[ "$choice" == "0" ]]; then
            return
        elif [[ "$choice" == "a" ]]; then
            for app in "${!apps[@]}"; do
                SELECTED_APPS[$app]="${apps[$app]}"
            done
            log_info "已全选 $title 中的所有应用"
        elif [[ "$choice" == "c" ]]; then
            for app in "${!apps[@]}"; do
                unset SELECTED_APPS[$app]
            done
            log_info "已清空 $title 的选择"
        elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#app_keys[@]}" ]; then
            local app_key="${app_keys[$((choice-1))]}"
            if [[ -n "${SELECTED_APPS[$app_key]}" ]]; then
                unset SELECTED_APPS[$app_key]
                log_warn "已取消选择: ${apps[$app_key]}"
            else
                SELECTED_APPS[$app_key]="${apps[$app_key]}"
                log_info "已选择: ${apps[$app_key]}"
            fi
        else
            log_warn "无效选择: $choice"
        fi
    done
    
    read -p "按回车键继续..."
    show_app_menu "$category" $2 "$title"
}

# 显示已选择的应用
show_selected_apps() {
    clear
    echo -e "${CYAN}========================================"
    echo -e "        已选择的应用"
    echo -e "========================================${NC}"
    
    if [ ${#SELECTED_APPS[@]} -eq 0 ]; then
        echo -e "${YELLOW}暂未选择任何应用${NC}"
    else
        local i=1
        for app in "${!SELECTED_APPS[@]}"; do
            echo -e "${GREEN}$i.${NC} ${SELECTED_APPS[$app]}"
            ((i++))
        done
        echo ""
        echo -e "${BLUE}总计: ${#SELECTED_APPS[@]} 个应用${NC}"
    fi
    
    echo -e "${CYAN}========================================${NC}"
    read -p "按回车键返回..."
}

# 生成应用配置
generate_app_config() {
    local app=$1
    
    case $app in
        "qbittorrent")
            cat >> "$INSTALL_PATH/$COMPOSE_FILE" << EOF

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
EOF
            mkdir -p "$INSTALL_PATH/qbittorrent"
            ;;
            
        "transmission")
            cat >> "$INSTALL_PATH/$COMPOSE_FILE" << EOF

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
EOF
            mkdir -p "$INSTALL_PATH/transmission"
            ;;
            
        "sonarr")
            cat >> "$INSTALL_PATH/$COMPOSE_FILE" << EOF

  sonarr:
    image: linuxserver/sonarr:latest
    container_name: sonarr
    environment:
      - PUID=0
      - PGID=0
      - TZ=Asia/Shanghai
    volumes:
      - ./sonarr/config:/config
      - $DOWNLOAD_PATH:/downloads
      - $DOWNLOAD_PATH/tv:/tv
    ports:
      - "8989:8989"
    restart: unless-stopped
    networks:
      - pt-network
EOF
            mkdir -p "$INSTALL_PATH/sonarr"
            ;;
            
        "radarr")
            cat >> "$INSTALL_PATH/$COMPOSE_FILE" << EOF

  radarr:
    image: linuxserver/radarr:latest
    container_name: radarr
    environment:
      - PUID=0
      - PGID=0
      - TZ=Asia/Shanghai
    volumes:
      - ./radarr/config:/config
      - $DOWNLOAD_PATH:/downloads
      - $DOWNLOAD_PATH/movies:/movies
    ports:
      - "7878:7878"
    restart: unless-stopped
    networks:
      - pt-network
EOF
            mkdir -p "$INSTALL_PATH/radarr"
            ;;
            
        "prowlarr")
            cat >> "$INSTALL_PATH/$COMPOSE_FILE" << EOF

  prowlarr:
    image: linuxserver/prowlarr:latest
    container_name: prowlarr
    environment:
      - PUID=0
      - PGID=0
      - TZ=Asia/Shanghai
    volumes:
      - ./prowlarr/config:/config
    ports:
      - "9696:9696"
    restart: unless-stopped
    networks:
      - pt-network
EOF
            mkdir -p "$INSTALL_PATH/prowlarr"
            ;;
            
        "bazarr")
            cat >> "$INSTALL_PATH/$COMPOSE_FILE" << EOF

  bazarr:
    image: linuxserver/bazarr:latest
    container_name: bazarr
    environment:
      - PUID=0
      - PGID=0
      - TZ=Asia/Shanghai
    volumes:
      - ./bazarr/config:/config
      - $DOWNLOAD_PATH/movies:/movies
      - $DOWNLOAD_PATH/tv:/tv
    ports:
      - "6767:6767"
    restart: unless-stopped
    networks:
      - pt-network
EOF
            mkdir -p "$INSTALL_PATH/bazarr"
            ;;
            
        "jackett")
            cat >> "$INSTALL_PATH/$COMPOSE_FILE" << EOF

  jackett:
    image: linuxserver/jackett:latest
    container_name: jackett
    environment:
      - PUID=0
      - PGID=0
      - TZ=Asia/Shanghai
    volumes:
      - ./jackett/config:/config
      - $DOWNLOAD_PATH:/downloads
    ports:
      - "9117:9117"
    restart: unless-stopped
    networks:
      - pt-network
EOF
            mkdir -p "$INSTALL_PATH/jackett"
            ;;
            
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
    restart: unless-stopped
    networks:
      - pt-network
EOF
            mkdir -p "$INSTALL_PATH/emby"
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
    devices:
      - /dev/dri:/dev/dri
    restart: unless-stopped
    networks:
      - pt-network
EOF
            mkdir -p "$INSTALL_PATH/jellyfin"
            ;;
            
        "portainer")
            cat >> "$INSTALL_PATH/$COMPOSE_FILE" << EOF

  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: always
    ports:
      - "9000:9000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./portainer/data:/data
    networks:
      - pt-network
EOF
            mkdir -p "$INSTALL_PATH/portainer"
            ;;
            
        "filebrowser")
            cat >> "$INSTALL_PATH/$COMPOSE_FILE" << EOF

  filebrowser:
    image: hurlenko/filebrowser:latest
    container_name: filebrowser
    environment:
      - UID=0
      - GID=0
      - TZ=Asia/Shanghai
    ports:
      - "8081:8080"
    volumes:
      - ./filebrowser/config:/config
      - $DOWNLOAD_PATH:/data
      - /opt:/opt:ro
    restart: unless-stopped
    networks:
      - pt-network
EOF
            mkdir -p "$INSTALL_PATH/filebrowser"
            ;;
            
        "netdata")
            cat >> "$INSTALL_PATH/$COMPOSE_FILE" << EOF

  netdata:
    image: netdata/netdata:latest
    container_name: netdata
    hostname: netdata
    ports:
      - "19999:19999"
    restart: unless-stopped
    cap_add:
      - SYS_PTRACE
    security_opt:
      - apparmor:unconfined
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - pt-network
EOF
            ;;
            
        *)
            log_warn "未知应用: $app"
            ;;
    esac
}

# 生成完整的Docker Compose配置
generate_compose_config() {
    log_info "生成Docker Compose配置..."
    
    # 创建基础配置
    cat > "$INSTALL_PATH/$COMPOSE_FILE" << 'EOF'
version: '3.8'

services:
EOF

    # 添加网络配置占位符 (会在最后添加)
    echo "networks:" >> "$INSTALL_PATH/$COMPOSE_FILE"
    echo "  pt-network:" >> "$INSTALL_PATH/$COMPOSE_FILE" 
    echo "    driver: bridge" >> "$INSTALL_PATH/$COMPOSE_FILE"
    
    # 临时移除网络配置，稍后重新添加
    head -n -3 "$INSTALL_PATH/$COMPOSE_FILE" > temp_compose.yml
    mv temp_compose.yml "$INSTALL_PATH/$COMPOSE_FILE"
    
    # 生成选中应用的配置
    for app in "${!SELECTED_APPS[@]}"; do
        log_info "添加 $app 配置..."
        generate_app_config "$app"
    done
    
    # 添加网络配置
    cat >> "$INSTALL_PATH/$COMPOSE_FILE" << 'EOF'

networks:
  pt-network:
    driver: bridge
EOF
    
    log_info "Docker Compose配置生成完成"
}

# 创建目录结构
create_directories() {
    log_info "创建目录结构..."
    
    mkdir -p "$INSTALL_PATH"
    mkdir -p "$DOWNLOAD_PATH"/{movies,tv,music,books,temp}
    
    # 为选中的应用创建配置目录
    for app in "${!SELECTED_APPS[@]}"; do
        mkdir -p "$INSTALL_PATH/$app"
    done
    
    chmod -R 777 "$INSTALL_PATH" "$DOWNLOAD_PATH"
    log_info "目录创建完成"
}

# 显示安装摘要
show_install_summary() {
    clear
    echo -e "${CYAN}========================================"
    echo -e "           安装摘要"
    echo -e "========================================${NC}"
    echo -e "${GREEN}安装路径:${NC} $INSTALL_PATH"
    echo -e "${GREEN}下载路径:${NC} $DOWNLOAD_PATH"
    echo -e "${GREEN}应用数量:${NC} ${#SELECTED_APPS[@]}"
    echo ""
    echo -e "${GREEN}将要安装的应用:${NC}"
    
    local i=1
    for app in "${!SELECTED_APPS[@]}"; do
        echo -e "  ${BLUE}$i.${NC} ${SELECTED_APPS[$app]}"
        ((i++))
    done
    
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}注意: 安装过程可能需要较长时间，请耐心等待${NC}"
    echo ""
    read -p "确认开始安装? (y/N): " confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "安装已取消"
        return 1
    fi
    
    return 0
}

# 启动服务
start_services() {
    log_info "启动Docker服务..."
    cd "$INSTALL_PATH"
    
    log_info "拉取Docker镜像..."
    docker-compose pull
    
    log_info "启动容器..."
    docker-compose up -d
    
    log_info "等待服务启动..."
    sleep 15
    
    # 检查服务状态
    local failed_services=()
    while IFS= read -r line; do
        if [[ $line == *"Exit"* ]]; then
            local service_name=$(echo "$line" | awk '{print $1}')
            failed_services+=("$service_name")
        fi
    done < <(docker-compose ps)
    
    if [ ${#failed_services[@]} -eq 0 ]; then
        log_info "所有服务启动成功！"
        show_access_info
    else
        log_error "以下服务启动失败: ${failed_services[*]}"
        log_info "查看失败服务日志:"
        for service in "${failed_services[@]}"; do
            echo -e "${RED}=== $service 日志 ===${NC}"
            docker-compose logs --tail 20 "$service"
        done
    fi
}

# 显示访问信息
show_access_info() {
    local server_ip=$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP")
    
    clear
    echo -e "${CYAN}========================================"
    echo -e "        安装完成！访问信息"
    echo -e "========================================${NC}"
    
    # 下载管理工具
    local has_download=false
    for app in "${!SELECTED_APPS[@]}"; do
        case $app in
            "qbittorrent")
                if ! $has_download; then
                    echo -e "${GREEN}📥 下载管理工具:${NC}"
                    has_download=true
                fi
                echo -e "   qBittorrent:  http://$server_ip:8080"
                ;;
            "transmission")
                if ! $has_download; then
                    echo -e "${GREEN}📥 下载管理工具:${NC}"
                    has_download=true
                fi
                echo -e "   Transmission: http://$server_ip:9091 (admin/adminadmin)"
                ;;
            "aria2")
                if ! $has_download; then
                    echo -e "${GREEN}📥 下载管理工具:${NC}"
                    has_download=true
                fi
                echo -e "   Aria2:        http://$server_ip:6800 (RPC)"
                ;;
        esac
    done
    $has_download && echo ""
    
    # 自动化管理工具
    local has_automation=false
    for app in "${!SELECTED_APPS[@]}"; do
        case $app in
            "sonarr")
                if ! $has_automation; then
                    echo -e "${GREEN}🤖 自动化管理:${NC}"
                    has_automation=true
                fi
                echo -e "   Sonarr:       http://$server_ip:8989"
                ;;
            "radarr")
                if ! $has_automation; then
                    echo -e "${GREEN}🤖 自动化管理:${NC}"
                    has_automation=true
                fi
                echo -e "   Radarr:       http://$server_ip:7878"
                ;;
            "prowlarr")
                if ! $has_automation; then
                    echo -e "${GREEN}🤖 自动化管理:${NC}"
                    has_automation=true
                fi
                echo -e "   Prowlarr:     http://$server_ip:9696"
                ;;
            "bazarr")
                if ! $has_automation; then
                    echo -e "${GREEN}🤖 自动化管理:${NC}"
                    has_automation=true
                fi
                echo -e "   Bazarr:       http://$server_ip:6767"
                ;;
        esac
    done
    $has_automation && echo ""
    
    # 媒体服务器
    local has_media=false
    for app in "${!SELECTED_APPS[@]}"; do
        case $app in
            "emby")
                if ! $has_media; then
                    echo -e "${GREEN}📺 媒体服务器:${NC}"
                    has_media=true
                fi
                echo -e "   Emby:         http://$server_ip:8096"
                ;;
            "jellyfin")
                if ! $has_media; then
                    echo -e "${GREEN}📺 媒体服务器:${NC}"
                    has_media=true
                fi
                echo -e "   Jellyfin:     http://$server_ip:8096"
                ;;
            "plex")
                if ! $has_media; then
                    echo -e "${GREEN}📺 媒体服务器:${NC}"
                    has_media=true
                fi
                echo -e "   Plex:         http://$server_ip:32400/web"
                ;;
        esac
    done
    $has_media && echo ""
    
    # 搜索工具
    local has_search=false
    for app in "${!SELECTED_APPS[@]}"; do
        case $app in
            "jackett")
                if ! $has_search; then
                    echo -e "${GREEN}🔍 搜索工具:${NC}"
                    has_search=true
                fi
                echo -e "   Jackett:      http://$server_ip:9117"
                ;;
        esac
    done
    $has_search && echo ""
    
    # 管理工具
    local has_management=false
    for app in "${!SELECTED_APPS[@]}"; do
        case $app in
            "portainer")
                if ! $has_management; then
                    echo -e "${GREEN}🛠️ 管理工具:${NC}"
                    has_management=true
                fi
                echo -e "   Portainer:    http://$server_ip:9000"
                ;;
            "filebrowser")
                if ! $has_management; then
                    echo -e "${GREEN}🛠️ 管理工具:${NC}"
                    has_management=true
                fi
                echo -e "   FileBrowser:  http://$server_ip:8081"
                ;;
            "netdata")
                if ! $has_management; then
                    echo -e "${GREEN}🛠️ 管理工具:${NC}"
                    has_management=true
                fi
                echo -e "   Netdata:      http://$server_ip:19999"
                ;;
        esac
    done
    $has_management && echo ""
    
    echo -e "${GREEN}📁 目录信息:${NC}"
    echo -e "   下载目录: $DOWNLOAD_PATH"
    echo -e "   配置目录: $INSTALL_PATH"
    echo ""
    echo -e "${YELLOW}⚠️  首次使用建议:${NC}"
    echo -e "   1. 修改各应用的默认密码"
    echo -e "   2. 配置应用间的连接信息"
    echo -e "   3. 设置媒体库路径为 /media"
    echo -e "   4. 查看FAQ文档了解详细配置"
    echo -e "${CYAN}========================================${NC}"
}

# 主菜单循环
category_menu_loop() {
    while true; do
        show_category_menu
        read -p "请选择操作: " choice
        
        case $choice in
            1)
                show_app_menu "download" DOWNLOAD_APPS "下载管理工具"
                ;;
            2)
                show_app_menu "automation" AUTOMATION_APPS "自动化管理工具"
                ;;
            3)
                show_app_menu "media" MEDIA_APPS "媒体服务器"
                ;;
            4)
                show_app_menu "search" SEARCH_APPS "搜索工具"
                ;;
            5)
                show_app_menu "file" FILE_APPS "文件管理工具"
                ;;
            6)
                show_app_menu "network" NETWORK_APPS "网络工具"
                ;;
            7)
                show_app_menu "monitor" MONITOR_APPS "监控管理工具"
                ;;
            8)
                show_selected_apps
                ;;
            9)
                if [ ${#SELECTED_APPS[@]} -eq 0 ]; then
                    log_warn "请先选择要安装的应用"
                    read -p "按回车键继续..."
                    continue
                fi
                
                if show_install_summary; then
                    check_system
                    install_docker
                    create_directories
                    generate_compose_config
                    start_services
                    read -p "按回车键返回主菜单..."
                    return
                fi
                ;;
            0)
                return
                ;;
            *)
                log_warn "无效选择，请重新输入"
                sleep 2
                ;;
        esac
    done
}

# 检查系统环境
check_system() {
    log_info "检查系统环境..."
    
    if [[ $EUID -ne 0 ]]; then
        log_error "请使用root权限运行此脚本"
        exit 1
    fi
    
    if [[ ! -f /etc/os-release ]]; then
        log_error "无法识别系统类型"
        exit 1
    fi
    
    source /etc/os-release
    log_info "检测到系统: $PRETTY_NAME"
}

# 安装Docker
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
    echo -e "${CYAN}========================================"
    echo -e "           系统信息"
    echo -e "========================================${NC}"
    echo "系统: $(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "内核: $(uname -r)"
    echo "架构: $(uname -m)"
    echo "CPU: $(nproc) 核心"
    echo "内存: $(free -h | grep Mem | awk '{print $2}')"
    echo "磁盘: $(df -h / | tail -1 | awk '{print $2 " (已用: " $3 ")"}')"
    echo "Docker: $(docker --version 2>/dev/null || echo "未安装")"
    echo "Docker Compose: $(docker-compose --version 2>/dev/null || echo "未安装")"
    echo -e "${CYAN}========================================${NC}"
    read -p "按回车键返回主菜单..."
}

# 显示主菜单
show_main_menu() {
    clear
    echo -e "${CYAN}========================================"
    echo -e "    PT Docker 高级安装脚本 v2.0"
    echo -e "    作者: everett7623"
    echo -e "========================================${NC}"
    echo -e "${GREEN}1.${NC} 分类选择安装 (推荐)"
    echo -e "   - 支持多种应用分类"
    echo -e "   - 自由选择所需应用"
    echo ""
    echo -e "${GREEN}2.${NC} 自定义安装路径"
    echo -e "${GREEN}3.${NC} 查看系统信息"
    echo -e "${GREEN}4.${NC} 退出"
    echo -e "${CYAN}========================================${NC}"
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
                category_menu_loop
                ;;
            2)
                customize_paths
                ;;
            3)
                show_system_info
                ;;
            4)
                log_info "感谢使用PT Docker高级安装脚本！"
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
