#!/bin/bash

# 媒体服务器配置脚本
# 支持Emby、Jellyfin、Plex的安装和配置
# 作者: everett7623

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# 日志函数
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_blue() { echo -e "${BLUE}[INFO]${NC} $1"; }

# 支持的媒体服务器
declare -A MEDIA_SERVERS=(
    ["emby"]="Emby - 功能强大的媒体服务器"
    ["jellyfin"]="Jellyfin - 完全免费开源"
    ["plex"]="Plex - 主流媒体服务器"
)

# 生成Emby配置
generate_emby_config() {
    local install_path=$1
    local download_path=$2
    
    log_info "生成Emby配置..."
    
    cat >> "${install_path}/docker-compose.yml" << EOF

  emby:
    image: emby/embyserver:latest
    container_name: emby
    environment:
      - PUID=0
      - PGID=0
      - TZ=Asia/Shanghai
    volumes:
      - ./emby/config:/config
      - ${download_path}:/media
      - ./emby/cache:/cache
    ports:
      - "8096:8096"
      - "8920:8920"
    devices:
      - /dev/dri:/dev/dri
    restart: unless-stopped
    networks:
      - pt-network
EOF

    mkdir -p "${install_path}/emby"
    
    # 创建Emby配置说明文件
    cat > "${install_path}/emby/README.md" << 'EOF'
# Emby 配置说明

## 首次访问
- 访问地址: http://服务器IP:8096
- 创建管理员账户
- 选择语言和地区

## 媒体库配置
1. 控制台 → 媒体库 → 添加媒体库
2. 电影: /media/movies
3. 电视节目: /media/tv
4. 音乐: /media/music

## 转码设置
- 控制台 → 转码
- 硬件加速: Intel Quick Sync Video (如支持)
- 转码临时路径: /cache

## 网络设置
- 控制台 → 网络
- 公共端口号: 8096
- 启用HTTPS: 建议开启
EOF
}

# 生成Jellyfin配置
generate_jellyfin_config() {
    local install_path=$1
    local download_path=$2
    
    log_info "生成Jellyfin配置..."
    
    cat >> "${install_path}/docker-compose.yml" << EOF

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
      - ${download_path}:/media:ro
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

    mkdir -p "${install_path}/jellyfin"
    
    # 创建Jellyfin配置说明文件
    cat > "${install_path}/jellyfin/README.md" << 'EOF'
# Jellyfin 配置说明

## 首次访问
- 访问地址: http://服务器IP:8096
- 选择语言
- 创建用户账户

## 媒体库配置
1. 控制面板 → 媒体库 → 添加媒体库
2. 电影: /media/movies
3. 电视节目: /media/tv
4. 音乐: /media/music

## 播放设置
- 控制面板 → 播放
- 硬件加速: Intel Quick Sync Video
- 转码设置: 根据客户端自动调整

## 网络设置
- 控制面板 → 网络
- 公共端口: 8096
- 启用端口映射: 关闭
EOF
}

# 生成Plex配置
generate_plex_config() {
    local install_path=$1
    local download_path=$2
    
    log_info "生成Plex配置..."
    
    cat >> "${install_path}/docker-compose.yml" << EOF

  plex:
    image: plexinc/pms-docker:latest
    container_name: plex
    environment:
      - PUID=0
      - PGID=0
      - TZ=Asia/Shanghai
      - PLEX_CLAIM=
      - ADVERTISE_IP=http://\${SERVER_IP}:32400/
    volumes:
      - ./plex/config:/config
      - ./plex/transcode:/transcode
      - ${download_path}:/media:ro
    ports:
      - "32400:32400"
      - "3005:3005"
      - "8324:8324"
      - "32469:32469"
      - "1900:1900/udp"
      - "32410:32410/udp"
      - "32412:32412/udp"
      - "32413:32413/udp"
      - "32414:32414/udp"
    devices:
      - /dev/dri:/dev/dri
    restart: unless-stopped
    networks:
      - pt-network
EOF

    mkdir -p "${install_path}/plex"
    
    # 创建Plex配置说明文件
    cat > "${install_path}/plex/README.md" << 'EOF'
# Plex 配置说明

## 首次访问
- 访问地址: http://服务器IP:32400/web
- 登录Plex账户
- 完成服务器设置向导

## Claim Token 获取
1. 访问: https://plex.tv/claim
2. 登录账户获取token
3. 在docker-compose.yml中设置PLEX_CLAIM

## 媒体库配置
1. 设置 → 管理 → 媒体库 → 添加库
2. Movies (电影): /media/movies
3. TV Shows (电视节目): /media/tv
4. Music (音乐): /media/music

## 转码设置
- 设置 → 转码
- 转码器质量: 自动
- 硬件加速转码: 开启 (如支持)

## 网络设置
- 设置 → 网络
- 手动指定公共端口: 32400
EOF
}

# 显示媒体服务器选择菜单
show_media_server_menu() {
    clear
    echo -e "${BLUE}========================================"
    echo -e "        选择媒体服务器"
    echo -e "========================================${NC}"
    echo -e "${GREEN}1.${NC} Emby - 功能强大，付费解锁高级功能"
    echo -e "   • 优秀的转码性能"
    echo -e "   • 丰富的插件生态"
    echo -e "   • 良好的客户端支持"
    echo ""
    echo -e "${GREEN}2.${NC} Jellyfin - 完全免费开源"
    echo -e "   • 所有功能免费"
    echo -e "   • 活跃的开源社区"
    echo -e "   • 隐私保护优秀"
    echo ""
    echo -e "${GREEN}3.${NC} Plex - 主流媒体服务器"
    echo -e "   • 最完善的客户端生态"
    echo -e "   • 优秀的远程访问"
    echo -e "   • 强大的元数据识别"
    echo ""
    echo -e "${GREEN}4.${NC} 多选安装 (用空格分隔，如: 1 2)"
    echo -e "${GREEN}5.${NC} 跳过媒体服务器安装"
    echo -e "${BLUE}========================================${NC}"
}

# 处理媒体服务器选择
handle_media_server_selection() {
    local install_path=$1
    local download_path=$2
    local choices=$3
    
    local selected_servers=()
    
    for choice in $choices; do
        case $choice in
            1)
                selected_servers+=("emby")
                ;;
            2)
                selected_servers+=("jellyfin")
                ;;
            3)
                selected_servers+=("plex")
                ;;
            5)
                log_info "跳过媒体服务器安装"
                return 0
                ;;
            *)
                log_warn "无效选择: $choice"
                ;;
        esac
    done
    
    if [ ${#selected_servers[@]} -eq 0 ]; then
        log_warn "未选择任何媒体服务器"
        return 1
    fi
    
    # 安装选中的媒体服务器
    for server in "${selected_servers[@]}"; do
        install_media_server "$server" "$install_path" "$download_path"
    done
    
    return 0
}

# 安装单个媒体服务器
install_media_server() {
    local server=$1
    local install_path=$2
    local download_path=$3
    
    case $server in
        "emby")
            generate_emby_config "$install_path" "$download_path"
            ;;
        "jellyfin")
            generate_jellyfin_config "$install_path" "$download_path"
            ;;
        "plex")
            generate_plex_config "$install_path" "$download_path"
            ;;
        *)
            log_error "不支持的媒体服务器: $server"
            return 1
            ;;
    esac
    
    log_info "已添加 $server 配置"
}

# 检查硬件加速支持
check_hardware_acceleration() {
    log_info "检查硬件加速支持..."
    
    local gpu_support=""
    
    # 检查Intel Quick Sync Video
    if [ -d "/dev/dri" ]; then
        if ls /dev/dri/render* >/dev/null 2>&1; then
            gpu_support="${gpu_support}Intel Quick Sync Video, "
        fi
    fi
    
    # 检查NVIDIA GPU
    if command -v nvidia-smi &> /dev/null; then
        gpu_support="${gpu_support}NVIDIA NVENC, "
    fi
    
    # 检查AMD GPU
    if lspci | grep -i "vga.*amd" >/dev/null 2>&1; then
        gpu_support="${gpu_support}AMD VCE, "
    fi
    
    if [ -n "$gpu_support" ]; then
        gpu_support=${gpu_support%, }  # 移除最后的逗号和空格
        log_info "检测到硬件加速支持: $gpu_support"
        
        echo -e "${YELLOW}硬件加速配置建议:${NC}"
        echo "• 在媒体服务器设置中启用硬件转码"
        echo "• 确保Docker容器有权限访问GPU设备"
        echo "• 转码质量建议设置为'自动'"
    else
        log_warn "未检测到硬件加速支持，将使用软件转码"
    fi
}

# 创建媒体目录结构
create_media_directories() {
    local download_path=$1
    
    log_info "创建媒体目录结构..."
    
    # 创建标准媒体目录
    mkdir -p "${download_path}"/{movies,tv,music,anime,books,documentaries}
    
    # 创建分类子目录
    mkdir -p "${download_path}/movies"/{action,comedy,drama,horror,sci-fi,others}
    mkdir -p "${download_path}/tv"/{series,variety,documentary,others}
    mkdir -p "${download_path}/music"/{pop,rock,classical,jazz,others}
    
    # 设置权限
    chmod -R 755 "$download_path"
    
    log_info "媒体目录结构创建完成"
    
    echo -e "${BLUE}目录结构:${NC}"
    echo "📁 $download_path/"
    echo "  ├── 📁 movies/        # 电影"
    echo "  ├── 📁 tv/            # 电视剧"
    echo "  ├── 📁 music/         # 音乐"
    echo "  ├── 📁 anime/         # 动漫"
    echo "  ├── 📁 books/         # 电子书"
    echo "  └── 📁 documentaries/ # 纪录片"
}

# 生成媒体服务器配置向导
generate_media_config_guide() {
    local install_path=$1
    
    cat > "${install_path}/media-server-guide.md" << 'EOF'
# 媒体服务器配置指南

## 通用配置步骤

### 1. 首次设置
- 访问对应的Web界面
- 创建管理员账户
- 选择语言和地区设置

### 2. 媒体库配置
所有媒体服务器的媒体路径都统一为：
- 电影: `/media/movies`
- 电视剧: `/media/tv`
- 音乐: `/media/music`
- 动漫: `/media/anime`
- 纪录片: `/media/documentaries`

### 3. 转码设置
- 启用硬件加速（如果支持）
- 设置转码临时目录
- 根据网络带宽调整质量

### 4. 网络设置
- 配置远程访问
- 设置端口转发
- 启用HTTPS（推荐）

## 各服务器特色功能

### Emby 特色配置
- 插件管理：安装中文插件包
- 转码设置：优化硬件加速参数
- 用户管理：设置家庭共享

### Jellyfin 特色配置
- 完全免费：所有功能无限制
- 隐私保护：无数据收集
- 插件系统：丰富的第三方插件

### Plex 特色配置
- Plex Pass：付费订阅高级功能
- 远程访问：最佳的外网访问体验
- 客户端：最丰富的设备支持

## 性能优化建议

### 硬件要求
- CPU: 支持硬件转码的处理器
- 内存: 最少2GB，推荐4GB+
- 存储: SSD存放数据库和缓存

### 网络优化
- 内网带宽: 千兆网络
- 外网带宽: 根据同时观看人数调整
- CDN加速: 使用反向代理优化

### 存储优化
- 媒体文件: 机械硬盘存储
- 数据库: SSD存储
- 缓存目录: 内存盘或SSD
EOF

    log_info "媒体服务器配置指南已生成: ${install_path}/media-server-guide.md"
}

# 启动媒体服务器服务
start_media_servers() {
    local install_path=$1
    
    log_info "启动媒体服务器..."
    
    cd "$install_path"
    
    # 检查docker-compose.yml是否存在
    if [ ! -f "docker-compose.yml" ]; then
        log_error "Docker Compose配置文件不存在"
        return 1
    fi
    
    # 检查是否有媒体服务器配置
    local has_media_server=false
    for server in "${!MEDIA_SERVERS[@]}"; do
        if grep -q "container_name: $server" docker-compose.yml; then
            has_media_server=true
            break
        fi
    done
    
    if [ "$has_media_server" = false ]; then
        log_warn "未检测到媒体服务器配置"
        return 1
    fi
    
    # 拉取镜像
    log_info "拉取媒体服务器镜像..."
    docker-compose pull
    
    # 启动服务
    log_info "启动媒体服务器容器..."
    docker-compose up -d
    
    # 等待服务启动
    log_info "等待服务启动..."
    sleep 20
    
    # 检查服务状态
    check_media_server_status "$install_path"
}

# 检查媒体服务器状态
check_media_server_status() {
    local install_path=$1
    
    cd "$install_path"
    
    log_info "检查媒体服务器状态..."
    
    local running_servers=()
    local failed_servers=()
    
    for server in "${!MEDIA_SERVERS[@]}"; do
        if docker-compose ps | grep -q "$server.*Up"; then
            running_servers+=("$server")
        elif docker-compose ps | grep -q "$server"; then
            failed_servers+=("$server")
        fi
    done
    
    if [ ${#running_servers[@]} -gt 0 ]; then
        log_info "运行中的媒体服务器: ${running_servers[*]}"
        show_media_access_info "${running_servers[@]}"
    fi
    
    if [ ${#failed_servers[@]} -gt 0 ]; then
        log_error "启动失败的媒体服务器: ${failed_servers[*]}"
        for server in "${failed_servers[@]}"; do
            echo -e "${RED}=== $server 错误日志 ===${NC}"
            docker-compose logs --tail 10 "$server"
        done
        return 1
    fi
    
    return 0
}

# 显示媒体服务器访问信息
show_media_access_info() {
    local servers=("$@")
    local server_ip
    server_ip=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || echo "Your_Server_IP")
    
    echo ""
    echo -e "${BLUE}========================================"
    echo -e "        媒体服务器访问信息"
    echo -e "========================================${NC}"
    
    for server in "${servers[@]}"; do
        case $server in
            "emby")
                echo -e "${GREEN}📺 Emby:${NC}"
                echo -e "   Web界面:  http://${server_ip}:8096"
                echo -e "   HTTPS:    https://${server_ip}:8920"
                echo -e "   配置指南: ./emby/README.md"
                ;;
            "jellyfin")
                echo -e "${GREEN}📺 Jellyfin:${NC}"
                echo -e "   Web界面:  http://${server_ip}:8096"
                echo -e "   HTTPS:    https://${server_ip}:8920"
                echo -e "   配置指南: ./jellyfin/README.md"
                ;;
            "plex")
                echo -e "${GREEN}📺 Plex:${NC}"
                echo -e "   Web界面:  http://${server_ip}:32400/web"
                echo -e "   配置指南: ./plex/README.md"
                echo -e "   Claim Token: https://plex.tv/claim"
                ;;
        esac
        echo ""
    done
    
    echo -e "${YELLOW}📋 配置提醒:${NC}"
    echo -e "   1. 媒体库路径统一设置为 /media"
    echo -e "   2. 启用硬件转码以提升性能"
    echo -e "   3. 建议配置HTTPS和远程访问"
    echo -e "   4. 查看配置指南了解详细设置"
    echo -e "${BLUE}========================================${NC}"
}

# 交互式媒体服务器安装
interactive_install() {
    local install_path=$1
    local download_path=$2
    
    if [ -z "$install_path" ] || [ -z "$download_path" ]; then
        log_error "缺少必要参数"
        echo "用法: $0 interactive <安装路径> <下载路径>"
        return 1
    fi
    
    # 检查硬件加速支持
    check_hardware_acceleration
    echo ""
    
    # 创建媒体目录
    create_media_directories "$download_path"
    echo ""
    
    # 显示选择菜单
    show_media_server_menu
    
    read -p "请输入选择 (多选用空格分隔): " choices
    
    if [ -z "$choices" ]; then
        log_warn "未做任何选择，退出安装"
        return 1
    fi
    
    # 处理用户选择
    if handle_media_server_selection "$install_path" "$download_path" "$choices"; then
        # 生成配置指南
        generate_media_config_guide "$install_path"
        
        # 启动服务
        if start_media_servers "$install_path"; then
            log_info "媒体服务器安装完成！"
            return 0
        else
            log_error "媒体服务器启动失败"
            return 1
        fi
    else
        log_error "媒体服务器配置失败"
        return 1
    fi
}

# 批量安装媒体服务器
batch_install() {
    local install_path=$1
    local download_path=$2
    local servers=$3
    
    if [ -z "$install_path" ] || [ -z "$download_path" ] || [ -z "$servers" ]; then
        log_error "缺少必要参数"
        echo "用法: $0 batch <安装路径> <下载路径> <服务器列表>"
        echo "服务器列表: emby,jellyfin,plex (用逗号分隔)"
        return 1
    fi
    
    log_info "批量安装媒体服务器: $servers"
    
    # 创建媒体目录
    create_media_directories "$download_path"
    
    # 分割服务器列表
    IFS=',' read -ra server_array <<< "$servers"
    
    # 安装每个服务器
    for server in "${server_array[@]}"; do
        server=$(echo "$server" | xargs)  # 去除空格
        if [[ " ${!MEDIA_SERVERS[@]} " =~ " $server " ]]; then
            install_media_server "$server" "$install_path" "$download_path"
        else
            log_warn "不支持的媒体服务器: $server"
        fi
    done
    
    # 生成配置指南
    generate_media_config_guide "$install_path"
    
    # 启动服务
    if start_media_servers "$install_path"; then
        log_info "批量安装完成！"
        return 0
    else
        log_error "部分服务启动失败"
        return 1
    fi
}

# 卸载媒体服务器
uninstall_media_servers() {
    local install_path=$1
    local servers=$2
    
    if [ -z "$install_path" ]; then
        log_error "缺少安装路径参数"
        return 1
    fi
    
    cd "$install_path"
    
    if [ -z "$servers" ]; then
        # 卸载所有媒体服务器
        log_warn "将卸载所有媒体服务器"
        servers="${!MEDIA_SERVERS[@]}"
    fi
    
    log_warn "警告: 此操作将删除指定媒体服务器及其配置！"
    read -p "确认卸载媒体服务器? (y/N): " confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "卸载操作已取消"
        return 0
    fi
    
    # 停止并删除容器
    for server in $servers; do
        if docker-compose ps | grep -q "$server"; then
            log_info "停止并删除 $server 容器..."
            docker-compose stop "$server"
            docker-compose rm -f "$server"
        fi
        
        # 删除配置目录
        if [ -d "./$server" ]; then
            log_info "删除 $server 配置目录..."
            rm -rf "./$server"
        fi
    done
    
    log_info "媒体服务器卸载完成"
}

# 显示帮助信息
show_help() {
    echo "媒体服务器配置脚本"
    echo ""
    echo "用法: $0 <命令> [参数]"
    echo ""
    echo "命令:"
    echo "  interactive <安装路径> <下载路径>        交互式安装"
    echo "  batch <安装路径> <下载路径> <服务器>    批量安装"
    echo "  install <服务器> <安装路径> <下载路径>  安装单个服务器"
    echo "  uninstall <安装路径> [服务器]           卸载媒体服务器"
    echo "  status <安装路径>                       检查服务状态"
    echo "  help                                    显示帮助"
    echo ""
    echo "支持的媒体服务器:"
    for server in "${!MEDIA_SERVERS[@]}"; do
        echo "  $server - ${MEDIA_SERVERS[$server]}"
    done
    echo ""
    echo "示例:"
    echo "  $0 interactive /opt/docker /opt/downloads"
    echo "  $0 batch /opt/docker /opt/downloads emby,jellyfin"
    echo "  $0 install emby /opt/docker /opt/downloads"
    echo "  $0 uninstall /opt/docker emby"
}

# 主入口函数
main() {
    local command=$1
    
    case $command in
        "interactive")
            interactive_install "$2" "$3"
            ;;
        "batch")
            batch_install "$2" "$3" "$4"
            ;;
        "install")
            install_media_server "$2" "$3" "$4"
            ;;
        "uninstall")
            uninstall_media_servers "$2" "$3"
            ;;
        "status")
            check_media_server_status "$2"
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
