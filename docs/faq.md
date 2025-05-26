# 常见问题解答 (FAQ)

## 🚀 安装相关

### Q: 支持哪些操作系统？
**A:** 目前支持以下系统：
- Ubuntu 18.04+
- Debian 10+
- CentOS 7+
- 其他基于systemd的Linux发行版

### Q: 需要什么权限？
**A:** 需要root权限，因为要安装Docker、创建目录和设置权限。

### Q: 可以在NAS上使用吗？
**A:** 当前版本主要针对VPS/服务器设计，NAS支持将在v2.0版本中添加。

### Q: 安装失败怎么办？
**A:** 请检查：
1. 网络连接是否正常
2. 系统是否有足够的磁盘空间
3. 是否使用root权限运行
4. 查看错误日志排查具体问题

## 🔧 配置相关

### Q: 如何修改默认安装路径？
**A:** 运行脚本时选择"自定义安装路径"选项，或手动编辑脚本中的路径变量。

### Q: 端口冲突了怎么办？
**A:** 编辑 `/opt/docker/docker-compose.yml` 文件，修改端口映射：
```yaml
ports:
  - "新端口:原端口"
```
然后重启服务：
```bash
cd /opt/docker && docker-compose restart
```

### Q: 如何添加更多下载目录？
**A:** 编辑 `docker-compose.yml`，在volumes部分添加：
```yaml
volumes:
  - /新路径:/容器内路径
```

## 🛠️ 使用相关

### Q: 默认用户名密码是什么？
**A:** 
- **qBittorrent**: 首次访问时会要求设置
- **Transmission**: admin / adminadmin
- **其他应用**: 首次访问时设置

### Q: 如何查看应用日志？
**A:** 
```bash
cd /opt/docker
# 查看所有服务日志
docker-compose logs

# 查看特定服务日志
docker-compose logs qbittorrent
docker-compose logs -f moviepilot  # 实时查看
```

### Q: 服务无法启动怎么办？
**A:** 
1. 检查端口是否被占用：`netstat -tulpn | grep 端口号`
2. 查看容器状态：`docker-compose ps`
3. 查看详细日志：`docker-compose logs 服务名`
4. 重启服务：`docker-compose restart 服务名`

### Q: 如何更新应用版本？
**A:** 
```bash
cd /opt/docker
docker-compose pull      # 拉取最新镜像
docker-compose up -d     # 重启服务
docker image prune -f    # 清理旧镜像
```

## 📁 目录和权限

### Q: 下载文件权限问题？
**A:** 脚本已设置PUID=0和PGID=0避免权限问题。如仍有问题：
```bash
sudo chmod -R 777 /opt/downloads
sudo chown -R root:root /opt/downloads
```

### Q: 如何备份配置？
**A:** 备份整个配置目录：
```bash
tar -czf pt-docker-backup-$(date +%Y%m%d).tar.gz /opt/docker
```

### Q: 如何恢复配置？
**A:** 
```bash
# 停止服务
cd /opt/docker && docker-compose down

# 恢复配置
tar -xzf pt-docker-backup-*.tar.gz -C /

# 启动服务
docker-compose up -d
```

## 🌐 网络访问

### Q: 无法访问Web界面？
**A:** 检查：
1. 防火墙是否开放对应端口
2. 服务是否正常启动：`docker-compose ps`
3. 端口是否被占用：`netstat -tulpn | grep 端口`

### Q: 如何开放防火墙端口？
**A:** 
**Ubuntu/Debian:**
```bash
sudo ufw allow 8080/tcp  # qBittorrent
sudo ufw allow 9091/tcp  # Transmission
sudo ufw allow 8780/tcp  # IYUU Plus
sudo ufw allow 3000/tcp  # MoviePilot
```

**CentOS/RHEL:**
```bash
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

### Q: 如何设置反向代理？
**A:** 以Nginx为例：
```nginx
server {
    listen 80;
    server_name qb.yourdomain.com;
    
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 📺 媒体服务器

### Q: Emby/Jellyfin/Plex如何选择？
**A:** 
- **Emby**: 功能最全面，付费解锁高级功能，适合追求稳定性
- **Jellyfin**: 完全免费开源，功能丰富，适合DIY用户
- **Plex**: 生态最完善，客户端最多，适合家庭用户

### Q: 媒体服务器无法硬件转码？
**A:** 确保：
1. 服务器支持硬件加速 (Intel Quick Sync/NVIDIA NVENC)
2. 容器已映射GPU设备：`/dev/dri:/dev/dri`
3. 在媒体服务器中启用硬件转码设置

### Q: 媒体库扫描不到文件？
**A:** 检查：
1. 文件路径映射是否正确
2. 媒体库路径设置为 `/media`
3. 文件权限是否正确
4. 文件格式是否支持

## 🔄 维护相关

### Q: 如何定期清理Docker？
**A:** 创建清理脚本：
```bash
#!/bin/bash
# 清理未使用的镜像
docker image prune -f

# 清理未使用的容器
docker container prune -f

# 清理未使用的网络
docker network prune -f

# 清理未使用的卷
docker volume prune -f
```

### Q: 如何监控服务状态？
**A:** 可以使用以下命令：
```bash
# 查看服务状态
docker-compose ps

# 查看资源使用
docker stats

# 设置自动重启
docker-compose up -d --force-recreate
```

## 🆘 获取帮助

### Q: 遇到问题如何获取帮助？
**A:** 
1. 查看本FAQ文档
2. 在GitHub Issues中搜索相关问题
3. 提交新的Issue，请包含：
   - 操作系统信息
   - 错误日志
   - 复现步骤
   - 期望结果

### Q: 如何贡献代码？
**A:** 
1. Fork项目仓库
2. 创建功能分支
3. 提交Pull Request
4. 详细描述修改内容

---

💡 如果你的问题没有在这里找到答案，欢迎在GitHub Issues中提问！
