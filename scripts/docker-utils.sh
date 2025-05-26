#!/bin/bash

# Docker 工具脚本
# 提供常用的Docker管理功能
# 作者: everett7623

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 默认配置
DOCKER_PATH="/opt/docker"
BACKUP_PATH="/opt/backups"

# 日志函数
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_blue() { echo -e "${BLUE}[INFO]${NC} $1"; }

# 检查Docker环境
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，请先安装Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose未安装，请先安装Docker Compose"
        exit 1
    fi
    
    if [ ! -d "$DOCKER_PATH" ]; then
        log_error "Docker配置目录不存在: $DOCKER_PATH"
        exit 1
    fi
}

# 显示服务状态
show_status() {
    log_info "检查Docker服务状态..."
    cd "$DOCKER_PATH"
    
    echo -e "${BLUE}=== Docker 服务状态 ===${NC}"
    docker-compose ps
    
    echo -e "\n${BLUE}=== Docker 系统信息 ===${NC}"
    docker system df
    
    echo -e "\n${BLUE}=== 容器资源使用 ===${NC}"
    docker stats --no-stream
}

# 更新所有服务
update_services() {
    log_info "更新所有Docker服务..."
    cd "$DOCKER_PATH"
    
    log_info "备份当前配置..."
    cp docker-compose.yml docker-compose.yml.backup
    
    log_info "拉取最新镜像..."
    docker-compose pull
    
    log_info "重启服务..."
    docker-compose up -d
    
    log_info "清理未使用的镜像..."
    docker image prune -f
    
    log_info "服务更新完成！"
}

# 重启服务
restart_services() {
    local service=$1
    cd "$DOCKER_PATH"
    
    if [ -z "$service" ]; then
        log_info "重启所有服务..."
        docker-compose restart
    else
        log_info "重启服务: $service"
        docker-compose restart "$service"
    fi
}

# 停止服务
stop_services() {
    local service=$1
    cd "$DOCKER_PATH"
    
    if [ -z "$service" ]; then
        log_info "停止所有服务..."
        docker-compose stop
    else
        log_info "停止服务: $service"
        docker-compose stop "$service"
    fi
}

# 启动服务
start_services() {
    local service=$1
    cd "$DOCKER_PATH"
    
    if [ -z "$service" ]; then
        log_info "启动所有服务..."
        docker-compose start
    else
        log_info "启动服务: $service"
        docker-compose start "$service"
    fi
}

# 查看日志
show_logs() {
    local service=$1
    local lines=${2:-100}
    local follow=${3:-false}
    
    cd "$DOCKER_PATH"
    
    if [ -z "$service" ]; then
        log_info "显示所有服务日志 (最近 $lines 行)..."
        if [ "$follow" = "true" ]; then
            docker-compose logs -f --tail="$lines"
        else
            docker-compose logs --tail="$lines"
        fi
    else
        log_info "显示 $service 服务日志 (最近 $lines 行)..."
        if [ "$follow" = "true" ]; then
            docker-compose logs -f --tail="$lines" "$service"
        else
            docker-compose logs --tail="$lines" "$service"
        fi
    fi
}

# 备份配置
backup_config() {
    local backup_name="pt-docker-backup-$(date +%Y%m%d_%H%M%S)"
    
    log_info "创建配置备份: $backup_name"
    
    mkdir -p "$BACKUP_PATH"
    
    # 停止服务
    log_info "停止服务以确保数据一致性..."
    cd "$DOCKER_PATH"
    docker-compose stop
    
    # 创建备份
    tar -czf "$BACKUP_PATH/$backup_name.tar.gz" \
        -C "$(dirname "$DOCKER_PATH")" \
        "$(basename "$DOCKER_PATH")" \
        --exclude='*/cache/*' \
        --exclude='*/logs/*' \
        --exclude='*/tmp/*'
    
    # 重启服务
    log_info "重新启动服务..."
    docker-compose start
    
    log_info "备份完成: $BACKUP_PATH/$backup_name.tar.gz"
    
    # 清理旧备份 (保留7天)
    find "$BACKUP_PATH" -name "pt-docker-backup-*.tar.gz" -mtime +7 -delete
}

# 恢复配置
restore_config() {
    local backup_file=$1
    
    if [ -z "$backup_file" ]; then
        log_error "请指定备份文件"
        echo "用法: $0 restore /path/to/backup.tar.gz"
        exit 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        log_error "备份文件不存在: $backup_file"
        exit 1
    fi
    
    log_warn "警告: 此操作将覆盖当前配置！"
    read -p "确认恢复备份? (y/N): " confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "恢复操作已取消"
        return
    fi
    
    # 停止服务
    log_info "停止当前服务..."
    cd "$DOCKER_PATH"
    docker-compose down
    
    # 备份当前配置
    log_info "备份当前配置..."
    backup_config
    
    # 恢复配置
    log_info "恢复配置文件..."
    tar -xzf "$backup_file" -C "$(dirname "$DOCKER_PATH")"
    
    # 启动服务
    log_info "启动服务..."
    cd "$DOCKER_PATH"
    docker-compose up -d
    
    log_info "配置恢复完成！"
}

# 清理系统
cleanup_system() {
    log_info "清理Docker系统..."
    
    log_info "清理未使用的镜像..."
    docker image prune -f
    
    log_info "清理未使用的容器..."
    docker container prune -f
    
    log_info "清理未使用的网络..."
    docker network prune -f
    
    log_info "清理未使用的卷..."
    docker volume prune -f
    
    log_info "清理构建缓存..."
    docker builder prune -f
    
    log_info "系统清理完成！"
}

# 重置服务
reset_service() {
    local service=$1
    
    if [ -z "$service" ]; then
        log_error "请指定要重置的服务名"
        return 1
    fi
    
    cd "$DOCKER_PATH"
    
    log_warn "警告: 此操作将删除 $service 的所有数据和配置！"
    read -p "确认重置服务 $service? (y/N): " confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "重置操作已取消"
        return
    fi
    
    # 停止并删除容器
    log_info "停止并删除容器..."
    docker-compose stop "$service"
    docker-compose rm -f "$service"
    
    # 删除配置目录
    if [ -d "./$service" ]; then
        log_info "删除配置目录..."
        rm -rf "./$service"
        mkdir -p "./$service"
        chmod 777 "./$service"
    fi
    
    # 重新创建容器
    log_info "重新创建容器..."
    docker-compose up -d "$service"
    
    log_info "服务 $service 重置完成！"
}

# 监控服务
monitor_services() {
    log_info "启动服务监控 (按 Ctrl+C 退出)..."
    
    while true; do
        clear
        echo -e "${BLUE}=== PT Docker 服务监控 $(date) ===${NC}"
        
        cd "$DOCKER_PATH"
        docker-compose ps
        
        echo -e "\n${BLUE}=== 资源使用情况 ===${NC}"
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
        
        echo -e "\n${BLUE}=== 磁盘使用情况 ===${NC}"
        df -h /opt
        
        sleep 5
    done
}

# 生成运维脚本
generate_maintenance_script() {
    local script_path="/usr/local/bin/pt-docker-maintenance"
    
    log_info "生成运维脚本: $script_path"
    
    cat > "$script_path" << 'EOF'
#!/bin/bash
# PT Docker 定时维护脚本

DOCKER_PATH="/opt/docker"
LOG_FILE="/var/log/pt-docker-maintenance.log"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 定时备份
backup_configs() {
    log_message "开始配置备份"
    /opt/docker/scripts/docker-utils.sh backup
    log_message "配置备份完成"
}

# 清理系统
cleanup_system() {
    log_message "开始系统清理"
    docker image prune -f
    docker container prune -f
    docker network prune -f
    docker volume prune -f
    log_message "系统清理完成"
}

# 更新服务
update_services() {
    log_message "开始服务更新"
    cd "$DOCKER_PATH"
    docker-compose pull
    docker-compose up -d
    log_message "服务更新完成"
}

# 检查服务健康状态
check_health() {
    log_message "开始健康检查"
    cd "$DOCKER_PATH"
    
    # 检查容器状态
    unhealthy_containers=$(docker-compose ps | grep -E "(Exit|Restarting)" | awk '{print $1}')
    
    if [ -n "$unhealthy_containers" ]; then
        log_message "发现异常容器: $unhealthy_containers"
        # 重启异常容器
        for container in $unhealthy_containers; do
            docker-compose restart "$container"
            log_message "重启容器: $container"
        done
    fi
    
    log_message "健康检查完成"
}

case "$1" in
    "backup")
        backup_configs
        ;;
    "cleanup")
        cleanup_system
        ;;
    "update")
        update_services
        ;;
    "health")
        check_health
        ;;
    *)
        echo "用法: $0 {backup|cleanup|update|health}"
        exit 1
        ;;
esac
EOF
    
    chmod +x "$script_path"
    
    # 创建定时任务
    log_info "配置定时任务..."
    
    cat > /etc/cron.d/pt-docker-maintenance << 'EOF'
# PT Docker 维护任务
# 每天凌晨2点备份
0 2 * * * root /usr/local/bin/pt-docker-maintenance backup

# 每周日凌晨3点清理系统  
0 3 * * 0 root /usr/local/bin/pt-docker-maintenance cleanup

# 每小时检查服务健康状态
0 * * * * root /usr/local/bin/pt-docker-maintenance health

# 每周一凌晨4点更新服务
0 4 * * 1 root /usr/local/bin/pt-docker-maintenance update
EOF
    
    log_info "运维脚本和定时任务配置完成"
}

# 显示帮助信息
show_help() {
    echo "PT Docker 工具脚本"
    echo ""
    echo "用法: $0 <命令> [参数]"
    echo ""
    echo "命令:"
    echo "  status                    显示服务状态"
    echo "  update                    更新所有服务"
    echo "  restart [服务名]          重启服务"
    echo "  stop [服务名]             停止服务"
    echo "  start [服务名]            启动服务"
    echo "  logs [服务名] [行数] [跟踪] 查看日志"
    echo "  backup                    备份配置"
    echo "  restore <备份文件>        恢复配置"
    echo "  cleanup                   清理系统"
    echo "  reset <服务名>            重置服务"
    echo "  monitor                   监控服务"
    echo "  maintenance               生成运维脚本"
    echo "  help                      显示帮助"
    echo ""
    echo "示例:"
    echo "  $0 status                 # 查看所有服务状态"
    echo "  $0 restart qbittorrent    # 重启qbittorrent服务"
    echo "  $0 logs moviepilot 50     # 查看moviepilot最近50行日志"
    echo "  $0 logs emby 100 true     # 实时跟踪emby日志"
    echo "  $0 backup                 # 备份配置"
    echo "  $0 cleanup                # 清理系统"
}

# 主函数
main() {
    local command=$1
    
    case $command in
        "status")
            check_docker
            show_status
            ;;
        "update")
            check_docker
            update_services
            ;;
        "restart")
            check_docker
            restart_services "$2"
            ;;
        "stop")
            check_docker
            stop_services "$2"
            ;;
        "start")
            check_docker
            start_services "$2"
            ;;
        "logs")
            check_docker
            show_logs "$2" "$3" "$4"
            ;;
        "backup")
            check_docker
            backup_config
            ;;
        "restore")
            check_docker
            restore_config "$2"
            ;;
        "cleanup")
            cleanup_system
            ;;
        "reset")
            check_docker
            reset_service "$2"
            ;;
        "monitor")
            check_docker
            monitor_services
            ;;
        "maintenance")
            generate_maintenance_script
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
