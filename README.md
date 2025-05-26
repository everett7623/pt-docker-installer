# PT Docker 一键安装脚本

🚀 为PT用户量身定制的Docker应用一键安装脚本，支持快速部署PT必备工具链。

## ✨ 特性

- 🎯 **一键安装** - 核心PT应用快速部署
- 🔧 **智能配置** - 自动处理目录结构和权限
- 📱 **交互界面** - 友好的命令行交互菜单
- 🎮 **灵活选择** - 支持媒体服务器多选安装
- 🔒 **安全可靠** - 完整的系统检查和错误处理

## 📦 包含应用

### 核心套件 (必装)
- **qBittorrent** - BT下载客户端 `:8080`
- **Transmission** - BT下载客户端 `:9091`
- **IYUU Plus** - PT自动化管理 `:8780`
- **MoviePilot** - 影视自动下载管理 `:3000`

### 媒体服务器 (可选)
- **Emby** - 功能强大的媒体服务器 `:8096`
- **Jellyfin** - 完全免费开源媒体服务器 `:8096`
- **Plex** - 主流媒体服务器 `:32400`

## 🚀 快速开始

### 一键安装
```bash
curl -fsSL https://raw.githubusercontent.com/everett7623/pt-docker-installer/main/install.sh | bash
```

### 手动安装
```bash
# 下载脚本
wget https://raw.githubusercontent.com/everett7623/pt-docker-installer/main/install.sh

# 添加执行权限
chmod +x install.sh

# 运行安装
sudo ./install.sh
```

## 📋 系统要求

- **操作系统**: Ubuntu 18.04+, Debian 10+, CentOS 7+
- **架构**: x86_64, ARM64
- **内存**: 建议 2GB+
- **磁盘**: 建议 20GB+ 可用空间
- **权限**: 需要 root 权限

## 🔧 默认配置

| 项目 | 默认值 | 说明 |
|------|--------|------|
| 安装路径 | `/opt/docker` | Docker配置文件目录 |
| 下载路径 | `/opt/downloads` | 下载文件存储目录 |
| 时区 | `Asia/Shanghai` | 容器时区设置 |
| 用户权限 | `PUID=0, PGID=0` | 避免权限问题 |

## 🌐 访问地址

安装完成后，可通过以下地址访问各应用：

```
qBittorrent:  http://你的IP:8080
Transmission: http://你的IP:9091 (用户名: admin, 密码: adminadmin)
IYUU Plus:    http://你的IP:8780
MoviePilot:   http://你的IP:3000
```

## 📚 使用指南

### 首次配置建议

1. **修改默认密码**
   - qBittorrent: 首次访问时设置
   - Transmission: 默认 admin/adminadmin，建议修改

2. **配置下载器连接**
   - 在IYUU Plus中配置qBittorrent和Transmission连接
   - MoviePilot中添加下载器配置

3. **设置媒体库路径**
   - 媒体服务器中设置媒体库路径为 `/media`
   - 这个路径映射到宿主机的下载目录

### 目录结构说明

```
/opt/docker/                 # 主配置目录
├── docker-compose.yml      # Docker Compose配置文件
├── qbittorrent/            # qBittorrent配置目录
├── transmission/           # Transmission配置目录
├── iyuuplus/              # IYUU Plus配置目录
├── moviepilot/            # MoviePilot配置目录
└── [媒体服务器]/           # 媒体服务器配置目录

/opt/downloads/             # 下载目录
├── movies/                # 电影
├── tv/                    # 电视剧
└── music/                 # 音乐
```

## 🛠️ 常见问题

### Q: 如何更新应用？
A: 在 `/opt/docker` 目录下执行：
```bash
docker-compose pull
docker-compose up -d
```

### Q: 如何查看日志？
A: 查看特定应用日志：
```bash
cd /opt/docker
docker-compose logs -f [应用名称]
```

### Q: 如何重启服务？
A: 重启所有服务：
```bash
cd /opt/docker
docker-compose restart
```

### Q: 端口冲突怎么办？
A: 编辑 `docker-compose.yml` 文件，修改端口映射：
```yaml
ports:
  - "新端口:8080"  # 修改左侧端口号
```

## 🔄 版本规划

### v1.0 (当前版本)
- ✅ 核心PT应用安装
- ✅ 媒体服务器选择
- ✅ 交互式安装界面

### v2.0 (计划中)
- 🔄 更多应用分类选择
- 🔄 配置文件自动优化
- 🔄 备份恢复功能
- 🔄 Web管理界面

## 🤝 贡献

欢迎提交 Issues 和 Pull Requests！

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 💡 致谢

感谢所有开源项目的贡献者们，让我们能够轻松部署这些优秀的应用。

---

⭐ 如果这个项目对你有帮助，请给个 Star 支持一下！
