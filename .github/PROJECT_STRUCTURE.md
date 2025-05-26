# PT Docker Installer 项目结构

## 📁 完整目录结构

```
pt-docker-installer/
├── README.md                           # 项目主说明文档
├── LICENSE                             # MIT开源许可证
├── version.txt                         # 版本信息
├── CHANGELOG.md                        # 更新日志
├── PROJECT_STRUCTURE.md                # 项目结构说明(本文件)
├── install.sh                          # 主安装脚本(v1.0基础版)
│
├── scripts/                            # 脚本目录
│   ├── advanced-installer.sh          # 高级安装脚本(v2.0预览版)
│   ├── docker-utils.sh                 # Docker工具脚本
│   ├── core-apps.sh                    # 核心应用安装脚本
│   ├── media-servers.sh                # 媒体服务器配置脚本
│   └── utils.sh                        # 通用工具函数
│
├── configs/                            # 配置文件目录
│   ├── docker-compose-templates.yml    # 所有应用的Docker Compose模板
│   ├── docker-compose/                 # 各应用独立配置
│   │   ├── qbittorrent.yml
│   │   ├── transmission.yml
│   │   ├── moviepilot.yml
│   │   ├── emby.yml
│   │   ├── jellyfin.yml
│   │   └── plex.yml
│   └── templates/                      # 配置模板
│       ├── nginx.conf.template
│       ├── qbittorrent.conf.template
│       └── environment.env.template
│
├── docs/                               # 文档目录
│   ├── installation.md                 # 详细安装指南
│   ├── configuration.md                # 配置指南
│   ├── troubleshooting.md              # 故障排除指南
│   ├── FAQ.md                          # 常见问题解答
│   ├── api.md                          # API文档(如有)
│   └── examples/                       # 示例配置
│       ├── basic-setup.md
│       ├── advanced-setup.md
│       └── nas-setup.md
│
├── tools/                              # 工具目录
│   ├── backup.sh                       # 备份工具
│   ├── restore.sh                      # 恢复工具
│   ├── cleanup.sh                      # 清理工具
│   ├── update.sh                       # 更新工具
│   └── monitor.sh                      # 监控工具
│
├── tests/                              # 测试目录
│   ├── test-install.sh                 # 安装测试脚本
│   ├── test-basic-functions.sh         # 基础功能测试
│   └── test-environments/              # 测试环境配置
│       ├── ubuntu-20.04.yml
│       ├── debian-11.yml
│       └── centos-8.yml
│
└── .github/                            # GitHub配置
    ├── workflows/                      # GitHub Actions
    │   ├── test.yml                    # 自动化测试
    │   ├── release.yml                 # 自动发布
    │   └── docker-build.yml            # Docker构建
    ├── ISSUE_TEMPLATE/                 # Issue模板
    │   ├── bug_report.md
    │   ├── feature_request.md
    │   └── question.md
    └── PULL_REQUEST_TEMPLATE.md        # PR模板
```

## 📋 文件说明

### 核心文件

| 文件 | 描述 | 用途 |
|------|------|------|
| `install.sh` | 主安装脚本 | v1.0版本，简单易用的一键安装 |
| `scripts/advanced-installer.sh` | 高级安装脚本 | v2.0版本，支持分类选择和更多应用 |
| `scripts/docker-utils.sh` | Docker工具脚本 | 提供维护、监控、备份等功能 |

### 配置文件

| 文件 | 描述 | 用途 |
|------|------|------|
| `configs/docker-compose-templates.yml` | 完整模板 | 包含所有支持应用的配置模板 |
| `configs/docker-compose/*.yml` | 独立配置 | 各应用的独立Docker Compose配置 |
| `configs/templates/*.template` | 配置模板 | 各种服务的配置文件模板 |

### 文档文件

| 文件 | 描述 | 目标用户 |
|------|------|----------|
| `README.md` | 项目主文档 | 所有用户 |
| `docs/installation.md` | 安装指南 | 新手用户 |
| `docs/configuration.md` | 配置指南 | 进阶用户 |
| `docs/FAQ.md` | 常见问题 | 遇到问题的用户 |
| `CHANGELOG.md` | 更新日志 | 关注更新的用户 |

## 🚀 开发规划

### v1.0 - 基础版本 ✅
- [x] 核心PT应用安装
- [x] 媒体服务器选择
- [x] 基础交互界面
- [x] 系统环境检查

### v1.1 - 优化版本 🔄
- [ ] 错误处理优化
- [ ] 日志系统完善
- [ ] 配置验证功能
- [ ] 性能优化

### v2.0 - 高级版本 📅
- [x] 分类应用选择
- [x] 更多应用支持
- [ ] Web管理界面
- [ ] 配置导入导出

### v2.1 - 企业版本 📅
- [ ] NAS系统支持
- [ ] 集群部署支持
- [ ] 高可用配置
- [ ] 企业级监控

### v3.0 - 云原生版本 🔮
- [ ] Kubernetes支持
- [ ] 微服务架构
- [ ] 云平台集成
- [ ] AI智能配置

## 🛠️ 开发指南

### 添加新应用

1. **更新应用定义**
   ```bash
   # 在 scripts/advanced-installer.sh 中添加
   declare -A NEW_CATEGORY_APPS=(
       ["new-app"]="New App - 应用描述"
   )
   ```

2. **创建配置函数**
   ```bash
   # 在 generate_app_config() 函数中添加
   "new-app")
       cat >> "$INSTALL_PATH/$COMPOSE_FILE" << EOF
   # 新应用配置
   EOF
       ;;
   ```

3. **更新模板文件**
   ```yaml
   # 在 configs/docker-compose-templates.yml 中添加
   new-app:
     image: new-app:latest
     # 完整配置...
   ```

4. **创建独立配置**
   ```bash
   # 创建 configs/docker-compose/new-app.yml
   ```

5. **更新文档**
   - 在README.md中添加应用说明
   - 在docs/configuration.md中添加配置指南
   - 更新CHANGELOG.md

### 脚本开发规范

#### 代码风格
```bash
#!/bin/bash
# 脚本说明
# 作者: everett7623

set -e  # 遇到错误立即退出

# 变量定义 (大写)
DEFAULT_PATH="/opt/docker"

# 函数定义 (小写+下划线)
function_name() {
    local param=$1
    # 函数内容
}

# 日志函数使用
log_info "信息消息"
log_warn "警告消息"
log_error "错误消息"
```

#### 错误处理
```bash
# 检查命令执行结果
if ! command -v docker &> /dev/null; then
    log_error "Docker未安装"
    exit 1
fi

# 检查文件存在
if [ ! -f "$config_file" ]; then
    log_warn "配置文件不存在，使用默认配置"
fi
```

#### 用户交互
```bash
# 确认操作
read -p "确认执行操作? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    log_info "操作已取消"
    return
fi

# 选择菜单
echo "请选择选项:"
echo "1. 选项1"
echo "2. 选项2"
read -p "请输入选择: " choice
```

## 📦 发布流程

### 1. 版
