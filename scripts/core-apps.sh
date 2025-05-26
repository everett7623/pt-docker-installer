#!/bin/bash

# PT 核心应用安装脚本
# 专门用于安装PT用户必备的核心应用
# 作者: everett7623

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
log_blue() { echo -e "${BLUE}[INFO]${NC} $1"; }

# 核心应用列表
CORE_APPS=("qbittorrent" "transmission" "iyuuplus" "moviepilot")

# 生成qBittorrent配置
generate_qbittorrent_config() {
    local install_path=$1
    local download_path=$2
    
    log_info "生成qBittorrent配置..."
    
    cat >> "${install_path}/docker-compose.yml" << EOF

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
      - ${download_path}:/downloads
    ports:
      - "8080:8080"
      - "6881:6881"
      - "6881:6881/udp"
    restart: unless-stopped
    networks:
      - pt-network
EOF

    mkdir -p "${install_path}/qbittorrent"
}

# 生成Transmission配置
generate_transmission_config() {
    local install_path=$1
    local download_path=$2
    
    log_info "生成Transmission配置..."
    
    cat >> "${install_path}/docker-compose.yml" << EOF

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
      - ${download_path}:/downloads
    ports:
      - "9091:9091"
      - "51413:51413"
      - "51413:51413/udp"
    restart: unless-stopped
    networks:
      - pt-network
EOF

    mkdir -p "${install_path}/transmission"
}

# 生成IYUU Plus配置
generate_iyuuplus_config() {
    local install_path=$1
    
    log_info "生成IYUU Plus配置..."
    
    cat >> "${install_path}/docker-compose.yml" << EOF

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
EOF

    mkdir -p "${install_path}/iyuuplus"
}

# 生成MoviePilot配置
generate_moviepilot_config() {
    local install_path=$1
    local download_path=$2
    
    log_info "生成MoviePilot配置..."
    
    cat >> "${install_path}/docker-compose.yml" << EOF

  moviepilot:
    image: jxxghp/moviepilot-v2:latest
    container_name: moviepilot
    stdin_open: true
    tty: true
    hostname: moviepilot
    volumes:
      - ${download_path}:/media
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
EOF

    mkdir -p "${install_path}/moviepilot"
}

# 生成核心应用Docker Compose配置
generate_core_compose() {
    local install_path=$1
    local download_path=$2
    
    log_info "生成核心应用Docker Compose配置..."
    
    # 创建基础配置
    cat > "${install_path}/docker-compose.yml" << 'EOF'
version: '3.8'

services:
EOF

    # 生成各应用配置
    generate_qbittorrent_config "$install_path" "$download_path"
    generate_transmission_config "$install_path" "$download_path"
    generate_iyuuplus_config "$install_path"
    generate_moviepilot_config "$install_path" "$download_path"
    
    # 添加网络配置
    cat >> "${install_path}/docker-compose.yml" << 'EOF'

networks:
  pt-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
EOF

    log_info "核心应用配置生成完成"
}

# 创建核心应用目录结构
create_core_directories() {
    local install_path=$1
    local download_path=$2
    
    log_info "创建核心应用目录结构..."
    
    # 创建主目录
    mkdir -p "$install_path"
    mkdir -p "$download_path"
    
    # 创建下载子目录
    mkdir -p "${download_path}"/{movies,tv,music,anime,books,temp}
    
    # 创建应用配置目录
    for app in "${CORE_APPS[@]}"; do
        mkdir -p "${install_path}/${app}"
    done
    
    # 设置权限
    chmod -R 777 "$install_path" "$download_path"
    
    log_info "目录结构创建完成"
}

# 验证核心应用配置
validate_core_config() {
    local install_path=$1
    
    log_info "验证核心应用配置..."
    
    # 检查docker-compose.yml文件
    if [ ! -f "${install_path}/docker-compose.yml" ]; then
        log_error "Docker Compose配置文件不存在"
        return 1
    fi
    
    # 检查配置文件语法
    if ! docker-compose -f "${install_path}/docker-compose.yml" config > /dev/null 2>&1; then
        log_error "Docker Compose配置文件语法错误"
        return 1
    fi
    
    # 检查必要目录
    for app in "${CORE_APPS[@]}"; do
        if [ ! -d "${install_path}/${app}" ]; then
            log_error "应用配置目录不存在: ${app}"
            return 1
        fi
    done
    
    log_info "核心应用配置验证通过"
    return 0
}

# 启动核心应用服务
start_core_services() {
    local install_path=$1
    
    log_info "启动核心应用服务..."
    
    cd "$install_path"
    
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
    local failed_services=()
    while IFS= read -r line; do
        if [[ $line == *"Exit"* || $line == *"Restarting"* ]]; then
            local service_name=$(echo "$line" | awk '{print $1}')
            failed_services+=("$service_name")
        fi
    done < <(docker-compose ps 2>/dev/null)
    
    if [ ${#failed_services[@]} -eq 0 ]; then
        log_info "所有核心服务启动成功！"
        return 0
    else
        log_error "以下服务启动失败: ${failed_services[*]}"
        for service in "${failed_services[@]}"; do
            echo -e "${RED}=== $service 错误日志 ===${NC}"
            docker-compose logs --tail 10 "$service"
        done
        return 1
    fi
}

# 显示核心应用访问信息
show_core_access_info() {
    local server_ip
    server_ip=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || echo "Your_Server_IP")
    
    echo ""
    echo -e "${BLUE}========================================"
    echo -e "        核心应用访问信息"
    echo -e "========================================${NC}"
    echo -e "${GREEN}🔥 下载器:${NC}"
    echo -e "   qBittorrent:  http://${server_ip}:8080"
    echo -e "   Transmission: http://${server_ip}:9091 (admin/adminadmin)"
    echo ""
    echo -e "${GREEN}🤖 自动化工具:${NC}"
    echo -e "   IYUU Plus:    http://${server_ip}:8780"
    echo -e "   MoviePilot:   http://${server_ip}:3000"
    echo ""
    echo -e "${GREEN}📋 配置建议:${NC}"
    echo -e "   1. 首次访问qBittorrent会要求设置密码"
    echo -e "   2. 在IYUU Plus中配置下载器连接"
    echo -e "   3. 在MoviePilot中添加下载器和媒体服务器"
    echo -e "   4. 建议修改Transmission默认密码"
    echo -e "${BLUE}========================================${NC}"
}

# 主函数 - 安装核心应用
install_core_apps() {
    local install_path=$1
    local download_path=$2
    
    if [ -z "$install_path" ] || [ -z "$download_path" ]; then
        log_error "缺少必要参数"
        echo "用法: $0 install_core_apps <安装路径> <下载路径>"
        return 1
    fi
    
    log_info "开始安装PT核心应用..."
    
    # 创建目录结构
    create_core_directories "$install_path" "$download_path"
    
    # 生成配置文件
    generate_core_compose "$install_path" "$download_path"
    
    # 验证配置
    if ! validate_core_config "$install_path"; then
        log_error "配置验证失败"
        return 1
    fi
    
    # 启动服务
    if start_core_services "$install_path"; then
        show_core_access_info
        log_info "PT核心应用安装完成！"
        return 0
    else
        log_error "部分服务启动失败，请检查日志"
        return 1
    fi
}

# 卸载核心应用
uninstall_core_apps() {
    local install_path=$1
    
    if [ -z "$install_path" ]; then
        log_error "缺少安装路径参数"
        return 1
    fi
    
    if [ ! -d "$install_path" ]; then
        log_warn "安装目录不存在: $install_path"
        return 0
    fi
    
    log_warn "警告: 此操作将删除所有核心应用及其配置！"
    read -p "确认卸载核心应用? (y/N): " confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "卸载操作已取消"
        return 0
    fi
    
    cd "$install_path"
    
    # 停止并删除容器
    log_info "停止并删除容器..."
    docker-compose down -v 2>/dev/null || true
    
    # 删除镜像
    log_info "删除相关镜像..."
    docker rmi $(docker images | grep -E "(qbittorrent|transmission|iyuuplus|moviepilot)" | awk '{print $3}') 2>/dev/null || true
    
    log_info "核心应用卸载完成"
}

# 重启核心应用
restart_core_apps() {
    local install_path=$1
    
    if [ -z "$install_path" ] || [ ! -d "$install_path" ]; then
        log_error "无效的安装路径: $install_path"
        return 1
    fi
    
    log_info "重启核心应用..."
    
    cd "$install_path"
    docker-compose restart
    
    log_info "核心应用重启完成"
}

# 更新核心应用
update_core_apps() {
    local install_path=$1
    
    if [ -z "$install_path" ] || [ ! -d "$install_path" ]; then
        log_error "无效的安装路径: $install_path"
        return 1
    fi
    
    log_info "更新核心应用..."
    
    cd "$install_path"
    
    # 备份配置
    cp docker-compose.yml docker-compose.yml.backup
    
    # 拉取最新镜像
    docker-compose pull
    
    # 重启服务
    docker-compose up -d
    
    # 清理旧镜像
    docker image prune -f
    
    log_info "核心应用更新完成"
}

# 显示帮助信息
show_help() {
    echo "PT核心应用安装脚本"
    echo ""
    echo "用法: $0 <命令> [参数]"
    echo ""
    echo "命令:"
    echo "  install <安装路径> <下载路径>  安装核心应用"
    echo "  uninstall <安装路径>          卸载核心应用"
    echo "  restart <安装路径>            重启核心应用"
    echo "  update <安装路径>             更新核心应用"
    echo "  help                          显示帮助"
    echo ""
    echo "示例:"
    echo "  $0 install /opt/docker /opt/downloads"
    echo "  $0 restart /opt/docker"
    echo "  $0 update /opt/docker"
}

# 主入口
main() {
    local command=$1
    
    case $command in
        "install")
            install_core_apps "$2" "$3"
            ;;
        "uninstall")
            uninstall_core_apps "$2"
            ;;
        "restart")
            restart_core_apps "$2"
            ;;
        "update")
            update_core_apps "$2"
            ;;
        "help"|"--help"|"-h"|"")
            show_help
            ;;
        *)
            log_error "未知命令: $command"
            show_help
            exit 1
            ;;
    esac
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
