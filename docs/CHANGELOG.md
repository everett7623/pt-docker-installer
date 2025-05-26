# 更新日志

所有重要的项目变更都会记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
并且遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [未发布]

### 计划添加
- 更多PT应用选择安装
- NAS系统支持
- Web管理界面
- 自动备份恢复功能

## [1.0.0] - 2025-05-26

### 新增
- 🎉 首次发布PT Docker一键安装脚本
- ✨ 支持核心PT应用套件安装
  - qBittorrent 4.6.7
  - Transmission 4.0.5
  - IYUU Plus (最新开发版)
  - MoviePilot v2 (最新版)
- 🎮 交互式安装界面
- 📺 媒体服务器选择安装
  - Emby
  - Jellyfin
  - Plex
- 🔧 自动系统环境检查
- 🐳 Docker和Docker Compose自动安装
- 📁 智能目录结构创建
- 🌐 安装完成后显示访问信息
- ⚙️ 支持自定义安装路径
- 📊 系统信息查看功能
- 🛡️ 完整的错误处理和日志记录

### 技术特性
- 支持 Ubuntu 18.04+, Debian 10+, CentOS 7+
- 自动权限设置避免权限问题
- 网络隔离使用独立Docker网络
- 配置文件持久化存储
- 服务健康检查和启动验证

### 默认配置
- 安装路径: `/opt/docker`
- 下载路径: `/opt/downloads`
- 时区: `Asia/Shanghai`
- 用户权限: `PUID=0, PGID=0`

### 端口分配
- qBittorrent: 8080
- Transmission: 9091
- IYUU Plus: 8780
- MoviePilot: 3000/3001
- Emby: 8096/8920
- Jellyfin: 8096/8920/7359/1900
- Plex: 32400
