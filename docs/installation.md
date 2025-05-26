# 安装指南

本文档将详细介绍如何安装和配置PT Docker一键安装脚本。

## 📋 安装前准备

### 系统要求
- **操作系统**: Ubuntu 18.04+, Debian 10+, CentOS 7+
- **架构**: x86_64 或 ARM64
- **内存**: 最少 1GB，推荐 2GB+
- **磁盘空间**: 至少 20GB 可用空间
- **网络**: 稳定的互联网连接

### 权限要求
- 需要 root 用户权限
- 确保可以执行 sudo 命令

### 端口要求
确保以下端口未被占用：
- 8080 (qBittorrent)
- 9091 (Transmission)
- 8780 (IYUU Plus)
- 3000, 3001 (MoviePilot)
- 8096, 8920 (媒体服务器)

## 🚀 安装方法

### 方法一：一键安装 (推荐)
```bash
curl -fsSL https://raw.githubusercontent.com/everett7623/pt-docker-installer/main/install.sh | bash
```

### 方法二：下载后安装
```bash
# 下载安装脚本
wget https://raw.githubusercontent.com/everett7623/pt-docker-installer/main/install.sh

# 添加执行权限
chmod +x install.sh

# 运行安装脚本
sudo ./install.sh
```

### 方法三：Git克隆安装
```bash
# 克隆仓库
git clone https://github.com/everett7623/pt-docker-installer.git

# 进入目录
cd pt-docker-installer

# 运行安装脚本
sudo ./install.sh
```

## 📱 安装流程

### 1. 启动安装脚本
运行脚本后会看到主菜单：
```
========================================
    PT Docker 一键安装脚本 v1.0
    作者: everett7623
========================================
1. 安装PT核心套件 (推荐新手)
   - qBittorrent + Transmission
   - IYUU Plus + MoviePilot
   - 可选媒体服务器

2. 自定义安装路径
3. 查看系统信息
4. 退出
========================================
```

### 2. 选择安装选项
选择 `1` 开始安装核心套件，脚本会自动：
- 检查系统环境
- 安装Docker和Docker Compose
- 显示媒体服务器选择菜单

### 3. 媒体服务器选择
```
========================================
        选择媒体服务器 (可多选)
========================================
1. Emby (功能强大，付费解锁高级功能)
2. Jellyfin (完全免费开源)
3. Plex (免费基础功能，付费高级功能)
4. 跳过媒体服务器安装
========================================
```

可以输入多个选项，用空格分隔，如：`1 2`

### 4. 自动安装过程
脚本会自动完成：
- 创建目录结构
- 生成Docker Compose配置
- 拉取并启动所有服务
- 显示访问信息

## 🎛️ 自定义配置

### 修改安装路径
在主菜单选择 `2` 可以自定义安装路径：
```
当前配置:
安装路径: /opt/docker
下载路径: /opt/downloads

请输入Docker安装路径 (回车使用默认): /home/docker
请输入下载目录路径 (回车使用默认): /home/downloads
```

### 手动编辑配置
如需更详细的配置，可以在安装完成后编辑：
```bash
cd /opt/docker
nano docker-compose.yml
```

## 🔍 安装验证

### 检查服务状态
```bash
cd /opt/docker
docker-compose ps
```

正常情况下应该看到所有服务状态为 `Up`。

### 检查端口监听
```bash
netstat -tulpn | grep -E "(8080|9091|8780|3000)"
```

### 访问Web界面
根据安装完成后显示的访问信息，在浏览器中访问各个应用。

## 🛠️ 故障排除

### Docker安装失败
```bash
# 手动安装Docker
curl -fsSL https://get.docker.com | sh
systemctl start docker
systemctl enable docker

# 安装Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 权限问题
```bash
# 设置目录权限
sudo chmod -R 777 /opt/docker
sudo chmod -R 777 /opt/downloads

# 重启Docker服务
sudo systemctl restart docker
```

### 端口冲突
编辑 `docker-compose.yml` 文件，修改端口映射：
```yaml
ports:
  - "新端口:8080"  # 修改左侧端口
```

### 服务无法启动
```bash
# 查看详细日志
docker-compose logs 服务名

# 重新拉取镜像
docker-compose pull

# 强制重建容器
docker-compose up -d --force-recreate
```

## 🔄 卸载方法

### 完全卸载
```bash
# 停止并删除所有容器
cd /opt/docker
docker-compose down -v

# 删除镜像
docker rmi $(docker images -q)

# 删除配置目录
sudo rm -rf /opt/docker
sudo rm -rf /opt/downloads

# 卸载Docker (可选)
sudo apt-get remove docker docker-engine docker.io containerd runc
```

### 保留数据卸载
```bash
# 只停止服务
cd /opt/docker
docker-compose down

# 删除镜像但保留配置
docker rmi $(docker images -q)
```

## 📝 安装后配置

### 1. qBittorrent 配置
- 首次访问 `http://服务器IP:8080`
- 默认用户名: `admin`
- 密码在日志中查看: `docker-compose logs qbittorrent | grep password`
- 建议修改Web UI密码

### 2. Transmission 配置
- 访问 `http://
