# 配置指南

本文档详细介绍各个应用的配置方法和最佳实践。

## 🔧 通用配置

### Docker Compose 配置结构
```yaml
version: '3.8'
services:
  应用名:
    image: 镜像名:版本
    container_name: 容器名
    environment:
      - 环境变量
    volumes:
      - 主机路径:容器路径
    ports:
      - "主机端口:容器端口"
    restart: unless-stopped
    networks:
      - pt-network
```

### 目录映射说明
- **配置目录**: `./应用名/config` → `/config`
- **下载目录**: `/opt/downloads` → `/downloads` 或 `/media`
- **BT备份目录**: 用于应用间数据共享

## 📥 下载器配置

### qBittorrent 配置

#### 1. 首次访问设置
```bash
# 查看默认密码
docker-compose logs qbittorrent | grep "password"
```

#### 2. 基础设置
访问 `http://服务器IP:8080`：
- **Web UI** → **更改密码**
- **下载** → **保存管理**:
  - 默认保存路径: `/downloads`
  - 完成时保存路径: `/downloads/completed`
- **连接** → **端口设置**:
  - 连接端口: `6881`
  - 使用UPnP/NAT-PMP: 关闭

#### 3. 高级设置
```
# 下载设置
全局最大连接数: 200
每个torrent最大连接数: 100
全局最大上传连接数: 20

# 速度设置
全局下载速度限制: 0 (不限制)
全局上传速度限制: 根据带宽设置

# 队列设置
最大活动下载数: 5
最大活动上传数: 10
```

#### 4. RSS设置 (可选)
- **RSS** → **新订阅规则**
- 添加PT站点RSS地址
- 设置下载规则和过滤器

### Transmission 配置

#### 1. 访问设置
- 地址: `http://服务器IP:9091`
- 用户名: `admin`
- 密码: `adminadmin`

#### 2. 基础配置
- **Preferences** → **Downloading**:
  - Download to: `/downloads`
  - Call script when done: 关闭
- **Network**:
  - Peer port: `51413`
  - Use port forwarding: 关闭

#### 3. 修改登录密码
编辑配置文件：
```bash
docker-compose exec transmission vi /config/settings.json
```
修改：
```json
{
    "rpc-username": "新用户名",
    "rpc-password": "新密码"
}
```

## 🤖 自动化工具配置

### IYUU Plus 配置

#### 1. 首次设置
访问 `http://服务器IP:8780`：
- 点击 **爱语飞飞** 进入设置
- 获取并输入IYUU Token

#### 2. 下载器配置
- **客户端管理** → **添加客户端**:
  
**qBittorrent 配置**:
```
类型: qBittorrent
名称: qBittorrent
主机: http://qbittorrent:8080
用户名: [你的用户名]
密码: [你的密码]
```

**Transmission 配置**:
```
类型: Transmission
名称: Transmission  
主机: http://transmission:9091
用户名: admin
密码: adminadmin
```

#### 3. 站点配置
- **站点管理** → **添加站点**
- 输入PT站点的Cookie信息
- 设置自动辅种规则

#### 4. 辅种设置
- **辅种设置** → **规则配置**:
  - 自动辅种: 开启
  - 最小做种体积: 1GB
  - 最大做种体积: 100GB
  - 排除规则: 根据需要设置

### MoviePilot 配置

#### 1. 首次设置
访问 `http://服务器IP:3000`：
- 创建管理员账户
- 完成初始配置向导

#### 2. 下载器配置
**设置** → **下载器**:

**qBittorrent**:
```
名称: qBittorrent
类型: qBittorrent
主机: http://qbittorrent:8080
端口: 8080
用户名: [你的用户名]
密码: [你的密码]
下载目录: /downloads
```

**Transmission**:
```
名称: Transmission
类型: Transmission
主机: http://transmission:9091
端口: 9091
用户名: admin
密码: adminadmin
```

#### 3. 媒体服务器配置
**设置** → **媒体服务器**:

**Emby 配置**:
```
名称: Emby
类型: Emby
地址: http://emby:8096
API密钥: [从Emby获取]
```

**Jellyfin 配置**:
```
名称: Jellyfin
类型: Jellyfin
地址: http://jellyfin:8096
API密钥: [从Jellyfin获取]
```

#### 4. 目录设置
**设置** → **目录**:
```
电影目录: /media/movies
电视剧目录: /media/tv
动漫目录: /media/anime
```

#### 5. 索引器配置
- 添加PT站点作为索引器
- 配置搜索和下载规则
- 设置自动订阅功能

## 📺 媒体服务器配置

### Emby 配置

#### 1. 首次设置
访问 `http://服务器IP:8096`：
- 创建管理员账户
- 选择语言和地区

#### 2. 媒体库设置
**控制台** → **媒体库**:
- **添加媒体库** → 选择类型:
  - 电影: `/media/movies`
  - 电视节目: `/media/tv`
  - 音乐: `/media/music`

#### 3. 转码设置
**控制台** → **转码**:
- 硬件加速: Intel Quick Sync Video (如支持)
- 转码临时路径: `/tmp`

#### 4. 网络设置
**控制台** → **网络**:
- 公共端口号: `8096`
- 启用HTTPS: 建议开启
- 远程访问: 根据需要开启

### Jellyfin 配置

#### 1. 首次设置
访问 `http://服务器IP:8096`：
- 选择语言
- 创建用户账户

#### 2. 媒体库配置
**控制面板** → **媒体库**:
- **添加媒体库**:
  - 内容类型: 电影
  - 文件夹: `/media/movies`
  
重复添加电视剧、音乐等媒体库。

#### 3. 播放设置
**控制面板** → **播放**:
- 硬件加速: Intel Quick Sync Video
- 转码设置: 根据客户端自动调整

#### 4. 网络设置
**控制面板** → **网络**:
- 公共端口: `8096`
- 启用端口映射: 关闭
- 远程连接: 根据需要配置

### Plex 配置

#### 1. 首次设置
访问 `http://服务器IP:32400/web`：
- 登录Plex账户
- 完成服务器设置向导

#### 2. 媒体库配置
**设置** → **管理** → **媒体库**:
- **添加库** → 选择类型:
  - Movies (电影): `/media/movies`
  - TV Shows (电视节目): `/media/tv`
  - Music (音乐): `/media/music`

#### 3. 转码设置
**设置** → **转码**:
- 转码器质量: 自动
- 后台转录: 开启
- 硬件加速转码: 开启 (如支持)

#### 4. 网络设置
**设置** → **网络**:
- 手动指定公共端口: `32400`
- 远程访问: 根据需要开启

## 🔗 应用间连接配置

### 下载器与自动化工具连接

#### IYUU Plus 连接下载器
使用Docker内部网络地址：
- qBittorrent: `http://qbittorrent:8080`
- Transmission: `http://transmission:9091`

#### MoviePilot 连接下载器
同样使用内部网络地址：
- qBittorrent: `http://qbittorrent:8080`
- Transmission: `http://transmission:9091`

### 自动化工具与媒体服务器连接

#### MoviePilot 连接媒体服务器
- Emby: `http://emby:8096`
- Jellyfin: `http://jellyfin:8096`
- Plex: `http://plex:32400`

## 🚀 性能优化配置

### 下载器优化

#### qBittorrent 优化
```
# 性能设置
异步I/O线程: 8
文件池大小: 500
磁盘缓存: 64MB
磁盘缓存TTL: 60

# 连接设置  
全局最大连接数: 200
每个种子最大连接数: 50
```

#### Transmission 优化
编辑 `settings.json`：
```json
{
    "cache-size-mb": 64,
    "max-peers-global": 200,
    "peer-limit-per-torrent": 50,
    "preallocation": 1,
    "prefetch-enabled": true
}
```

### 媒体服务器优化

#### 通用优化设置
```yaml
# Docker Compose 中添加
deploy:
  resources:
    limits:
      memory: 2G
    reservations:
      memory: 1G
```

#### Emby/Jellyfin 转码优化
```
# 转码设置
最大转码数: 2
转码临时目录: /tmp (使用内存)
硬件加速: 开启
预转码: 开启低码率版本
```

## 🔒 安全配置

### 修改默认密码

#### qBittorrent
1. 访问Web UI
2. **工具** → **选项** → **Web UI**
3. 修改用户名和密码

#### Transmission
编辑配置后重启：
```bash
docker-compose exec transmission vi /config/settings.json
docker-compose restart transmission
```

#### 各媒体服务器
在各自的管理界面中修改管理员密码。

### 网络安全设置

#### 使用反向代理
创建 `nginx.conf`：
```nginx
server {
    listen 80;
    server_name qb.yourdomain.com;
    
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

#### SSL证书配置
使用Let's Encrypt：
```bash
certbot --nginx -d yourdomain.com
```

## 📊 监控配置

### 日志配置
各应用日志路径：
```
qBittorrent: ./qbittorrent/config/qBittorrent.log
Transmission: docker-compose logs transmission
IYUU Plus: docker-compose logs iyuuplus  
MoviePilot: docker-compose logs moviepilot
```

### 资源监控
添加监控容器：
```yaml
  netdata:
    image: netdata/netdata
    container_name: netdata
    hostname: netdata
    ports:
      - 19999:19999
    restart: unless-stopped
    cap_add:
      - SYS_PTRACE
    security_opt:
      - apparmor:unconfined
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
```

## 🔄 备份配置

### 自动备份脚本
创建 `backup.sh`：
```bash
#!/bin/bash
BACKUP_DIR="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# 创建备份目录
mkdir -p $BACKUP_DIR

# 停止服务
cd /opt/docker
docker-compose stop

# 备份配置
tar -czf $BACKUP_DIR/pt-docker-config-$DATE.tar.gz \
    /opt/docker \
    --exclude='*/logs/*' \
    --exclude='*/cache/*'

# 启动服务
docker-compose start

# 清理老备份(保留7天)
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "备份完成: pt-docker-config-$DATE.tar.gz"
```

### 定时备份
添加到crontab：
```bash
# 每天凌晨2点备份
0 2 * * * /opt/docker/backup.sh
```

## 🛠️ 故障排除配置

### 常见配置问题

#### 权限问题
```bash
# 修复下载目录权限
chmod -R 777 /opt/downloads
chown -R root:root /opt/downloads

# 修复配置目录权限  
chmod -R 755 /opt/docker
```

#### 端口冲突
修改 `docker-compose.yml` 端口映射：
```yaml
ports:
  - "新端口:容器端口"
```

#### 内存不足
限制容器内存使用：
```yaml
deploy:
  resources:
    limits:
      memory: 512M
```

### 日志分析
```bash
# 查看服务启动日志
docker-compose logs --tail=100 服务名

# 实时查看日志
docker-compose logs -f 服务名

# 查看系统资源使用
docker stats
```

## 📝 配置文件模板

### 环境变量配置
创建 `.env` 文件：
```env
# 基础配置
TZ=Asia/Shanghai
PUID=0
PGID=0

# 路径配置
DOCKER_ROOT=/opt/docker
DOWNLOAD_ROOT=/opt/downloads

# 网络配置
QB_PORT=8080
TR_PORT=9091
IYUU_PORT=8780
MP_PORT=3000

# 数据库配置(如需要)
DB_HOST=localhost
DB_NAME=moviepilot
DB_USER=root
DB_PASS=password
```

在 `docker-compose.yml` 中使用：
```yaml
environment:
  - TZ=${TZ}
  - PUID=${PUID}
  - PGID=${PGID}
ports:
  - "${QB_PORT}:8080"
```

## 🎯 最佳实践

### 1. 目录结构规范
```
/opt/downloads/
├── movies/          # 电影
├── tv/             # 电视剧
├── anime/          # 动漫
├── music/          # 音乐
├── books/          # 电子书
└── temp/           # 临时下载
```

### 2. 命名规范
- 电影: `电影名 (年份)/电影名.年份.质量.格式`
- 电视剧: `剧名/Season XX/剧名.SxxExx.集名.格式`

### 3. 自动化设置
- 启用自动分类下载
- 设置完成后自动移动
- 配置自动刮削媒体信息
- 启用字幕自动下载

### 4. 维护建议
- 定期清理日志文件
- 监控磁盘空间使用
- 定期更新Docker镜像
- 备份重要配置文件

---

✅ 按照本指南完成配置后，你将拥有一个功能完整、自动化程度很高的PT环境！
