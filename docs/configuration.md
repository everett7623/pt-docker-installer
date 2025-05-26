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
- 完成服
