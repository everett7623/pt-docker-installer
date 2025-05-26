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
    echo "  ├── 📁 movies
