#!/bin/bash

# PT Docker 安装修复脚本
# 修复当前安装中的问题

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

INSTALL_PATH="/opt/docker"
DOWNLOAD_PATH="/opt/downloads"

log_info "开始修复PT Docker安装..."

# 停止当前服务
log_info "停止当前服务..."
cd "$INSTALL_PATH"
docker-compose down 2>/dev/null || true

# 备份当前配置
log_info "备份当前配置..."
cp docker-compose.yml docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)

# 生成正确的配置文件
log_info "生成修复后的配置文件..."
cat > docker-compose.yml << 'EOF'
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
      - /opt/downloads:/downloads
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
      - /opt/downloads:/downloads
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
      - /opt/downloads:/media
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

  emby:
    image: emby/embyserver:latest
    container_name: emby
    environment:
      - PUID=0
      - PGID=0
      - TZ=Asia/Shanghai
    volumes:
      - ./emby/config:/config
      - /opt/downloads:/media
    ports:
      - "8096:8096"
      - "8920:8920"
    devices:
      - /dev/dri:/dev/dri
    restart: unless-stopped
    networks:
      - pt-network

networks:
  pt-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
EOF

# 创建必要的目录
log_info "创建应用目录..."
mkdir -p qbittorrent transmission iyuuplus moviepilot emby
chmod -R 777 qbittorrent transmission iyuuplus moviepilot emby

# 验证配置文件
log_info "验证配置文件..."
if docker-compose config >/dev/null 2>&1; then
    log_info "配置文件验证通过 ✓"
else
    log_error "配置文件验证失败"
    exit 1
fi

# 启动服务
log_info "启动服务..."
docker-compose pull
docker-compose up -d

# 等待服务启动
log_info "等待服务启动..."
sleep 20

# 检查服务状态
log_info "检查服务状态..."
docker-compose ps

# 显示访问信息
SERVER_IP=$(curl -4 -s --connect-timeout 5 ifconfig.me 2>/dev/null || \
            curl -s --connect-timeout 5 ipv4.icanhazip.com 2>/dev/null || \
            hostname -I | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | head -1 || \
            echo "Your_Server_IP")

echo ""
echo -e "${BLUE}========================================"
echo -e "        修复完成！访问信息"
echo -e "========================================${NC}"
echo -e "${GREEN}🔥 核心应用:${NC}"
echo -e "   qBittorrent:  http://${SERVER_IP}:8080"
echo -e "   Transmission: http://${SERVER_IP}:9091 (admin/adminadmin)"
echo -e "   IYUU Plus:    http://${SERVER_IP}:8780"
echo -e "   MoviePilot:   http://${SERVER_IP}:3000"
echo ""
echo -e "${GREEN}📺 媒体服务器:${NC}"
echo -e "   Emby:         http://${SERVER_IP}:8096"
echo ""
echo -e "${YELLOW}⚠️  下一步操作:${NC}"
echo -e "   1. 等待2-3分钟让所有服务完全启动"
echo -e "   2. 访问上述地址检查服务是否正常"
echo -e "   3. 如有问题运行: docker-compose logs [服务名]"
echo -e "${BLUE}========================================${NC}"

log_info "修复脚本执行完成！"
