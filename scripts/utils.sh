#!/bin/bash

# 通用工具函数库
# 提供各种常用的工具函数
# 作者: everett7623

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# 日志级别
LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_WARN=2
LOG_LEVEL_ERROR=3

# 当前日志级别 (默认INFO)
CURRENT_LOG_LEVEL=${LOG_LEVEL:-$LOG_LEVEL_INFO}

# 日志函数
log_debug() {
    [ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_DEBUG ] && echo -e "${CYAN}[DEBUG]${NC} $1" >&2
}

log_info() {
    [ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_INFO ] && echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    [ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_WARN ] && echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() {
    [ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_ERROR ] && echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_highlight() {
    echo -e "${WHITE}[HIGHLIGHT]${NC} $1"
}

# 进度条函数
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))
    local remaining=$((width - completed))
    
    printf "\r["
    printf "%*s" $completed | tr ' ' '='
    printf "%*s" $remaining | tr ' ' '-'
    printf "] %d%% (%d/%d)" $percentage $current $total
}

# 完成进度条
finish_progress() {
    echo ""
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        return 1
    fi
    return 0
}

# 检查系统类型
get_os_type() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/redhat-release ]; then
        echo "centos"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

# 获取系统版本
get_os_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$VERSION_ID"
    else
        echo "unknown"
    fi
}

# 检查系统架构
get_arch() {
    local arch=$(uname -m)
    case $arch in
        x86_64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        armv7l)
            echo "armv7"
            ;;
        *)
            echo "$arch"
            ;;
    esac
}

# 获取系统信息
get_system_info() {
    local os_type=$(get_os_type)
    local os_version=$(get_os_version)
    local arch=$(get_arch)
    local kernel=$(uname -r)
    local cpu_cores=$(nproc)
    local memory=$(free -h | grep Mem | awk '{print $2}')
    
    echo "操作系统: $os_type $os_version"
    echo "架构: $arch"
    echo "内核: $kernel"
    echo "CPU核心: $cpu_cores"
    echo "内存: $memory"
}

# 检查端口是否被占用
check_port() {
    local port=$1
    if netstat -tuln | grep -q ":$port "; then
        return 0  # 端口被占用
    else
        return 1  # 端口未被占用
    fi
}

# 等待端口可用
wait_for_port() {
    local host=$1
    local port=$2
    local timeout=${3:-30}
    local count=0
    
    log_info "等待 $host:$port 端口可用..."
    
    while [ $count -lt $timeout ]; do
        if nc -z "$host" "$port" 2>/dev/null; then
            log_success "端口 $host:$port 已可用"
            return 0
        fi
        sleep 1
        ((count++))
    done
    
    log_error "等待端口 $host:$port 超时"
    return 1
}

# 获取外网IP
get_public_ip() {
    local ip=""
    
    # 尝试多个服务获取公网IP
    local services=(
        "ifconfig.me"
        "icanhazip.com" 
        "ipecho.net/plain"
        "checkip.amazonaws.com"
    )
    
    for service in "${services[@]}"; do
        ip=$(curl -s --connect-timeout 5 "$service" 2>/dev/null)
        if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            echo "$ip"
            return 0
        fi
    done
    
    # 如果都失败了，返回本地IP
    ip=$(hostname -I | awk '{print $1}')
    echo "${ip:-127.0.0.1}"
}

# 验证IP地址格式
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        local IFS='.'
        local -a octets=($ip)
        for octet in "${octets[@]}"; do
            if [ "$octet" -gt 255 ]; then
                return 1
            fi
        done
        return 0
    else
        return 1
    fi
}

# 验证域名格式
validate_domain() {
    local domain=$1
    if [[ $domain =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 0
    else
        return 1
    fi
}

# 生成随机密码
generate_password() {
    local length=${1:-16}
    local charset="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
    local password=""
    
    for ((i=0; i<length; i++)); do
        password="${password}${charset:RANDOM%${#charset}:1}"
    done
    
    echo "$password"
}

# 确认操作
confirm_action() {
    local message=${1:-"确认继续"}
    local default=${2:-"N"}
    
    if [ "$default" = "Y" ]; then
        read -p "$message? (Y/n): " -r reply
        reply=${reply:-Y}
    else
        read -p "$message? (y/N): " -r reply
        reply=${reply:-N}
    fi
    
    case $reply in
        [Yy]|[Yy][Ee][Ss])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# 创建目录并设置权限
create_directory() {
    local dir=$1
    local owner=${2:-root:root}
    local permissions=${3:-755}
    
    if [ ! -d "$dir" ]; then
        log_info "创建目录: $dir"
        mkdir -p "$dir"
    fi
    
    chown "$owner" "$dir"
    chmod "$permissions" "$dir"
}

# 备份文件
backup_file() {
    local file=$1
    local backup_dir=${2:-$(dirname "$file")}
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="$(basename "$file").backup.$timestamp"
    
    if [ -f "$file" ]; then
        log_info "备份文件: $file -> $backup_dir/$backup_name"
        cp "$file" "$backup_dir/$backup_name"
        return 0
    else
        log_warn "文件不存在，无法备份: $file"
        return 1
    fi
}

# 下载文件
download_file() {
    local url=$1
    local output=${2:-$(basename "$url")}
    local timeout=${3:-30}
    
    log_info "下载文件: $url"
    
    if command_exists curl; then
        curl -L -o "$output" --connect-timeout "$timeout" "$url"
    elif command_exists wget; then
        wget -O "$output" --timeout="$timeout" "$url"
    else
        log_error "未找到下载工具 (curl 或 wget)"
        return 1
    fi
}

# 检查磁盘空间
check_disk_space() {
    local path=$1
    local required_gb=$2
    
    local available_kb=$(df "$path" | tail -1 | awk '{print $4}')
    local available_gb=$((available_kb / 1024 / 1024))
    
    if [ "$available_gb" -ge "$required_gb" ]; then
        log_info "磁盘空间检查通过: ${available_gb}GB 可用 (需要 ${required_gb}GB)"
        return 0
    else
        log_error "磁盘空间不足: ${available_gb}GB 可用 (需要 ${required_gb}GB)"
        return 1
    fi
}

# 检查内存大小
check_memory() {
    local required_gb=$1
    local available_gb=$(free -g | grep Mem | awk '{print $2}')
    
    if [ "$available_gb" -ge "$required_gb" ]; then
        log_info "内存检查通过: ${available_gb}GB 可用 (需要 ${required_gb}GB)"
        return 0
    else
        log_warn "内存可能不足: ${available_gb}GB 可用 (建议 ${required_gb}GB)"
        return 1
    fi
}

# 安装系统包
install_package() {
    local package=$1
    local os_type=$(get_os_type)
    
    log_info "安装软件包: $package"
    
    case $os_type in
        ubuntu|debian)
            apt-get update && apt-get install -y "$package"
            ;;
        centos|rhel|rocky|almalinux)
            if command_exists dnf; then
                dnf install -y "$package"
            else
                yum install -y "$package"
            fi
            ;;
        fedora)
            dnf install -y "$package"
            ;;
        arch)
            pacman -S --noconfirm "$package"
            ;;
        *)
            log_error "不支持的操作系统: $os_type"
            return 1
            ;;
    esac
}

# 启用系统服务
enable_service() {
    local service=$1
    
    log_info "启用服务: $service"
    
    if command_exists systemctl; then
        systemctl enable "$service"
        systemctl start "$service"
    elif command_exists service; then
        service "$service" start
        chkconfig "$service" on 2>/dev/null || true
    else
        log_error "无法启用服务: 未找到服务管理工具"
        return 1
    fi
}

# 检查服务状态
check_service() {
    local service=$1
    
    if command_exists systemctl; then
        if systemctl is-active --quiet "$service"; then
            log_info "服务 $service 正在运行"
            return 0
        else
            log_warn "服务 $service 未运行"
            return 1
        fi
    elif command_exists service; then
        if service "$service" status >/dev/null 2>&1; then
            log_info "服务 $service 正在运行"
            return 0
        else
            log_warn "服务 $service 未运行"
            return 1
        fi
    else
        log_error "无法检查服务状态: 未找到服务管理工具"
        return 1
    fi
}

# 格式化字节大小
format_bytes() {
    local bytes=$1
    local units=("B" "KB" "MB" "GB" "TB")
    local unit=0
    
    while [ "$bytes" -ge 1024 ] && [ "$unit" -lt 4 ]; do
        bytes=$((bytes / 1024))
        ((unit++))
    done
    
    echo "${bytes}${units[$unit]}"
}

# 计算运行时间
format_duration() {
    local seconds=$1
    local days=$((seconds / 86400))
    local hours=$(((seconds % 86400) / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local secs=$((seconds % 60))
    
    if [ "$days" -gt 0 ]; then
        echo "${days}天${hours}小时${minutes}分钟"
    elif [ "$hours" -gt 0 ]; then
        echo "${hours}小时${minutes}分钟"
    elif [ "$minutes" -gt 0 ]; then
        echo "${minutes}分钟${secs}秒"
    else
        echo "${secs}秒"
    fi
}

# 生成配置文件
generate_config() {
    local template=$1
    local output=$2
    shift 2
    local vars=("$@")
    
    log_info "生成配置文件: $output"
    
    if [ ! -f "$template" ]; then
        log_error "模板文件不存在: $template"
        return 1
    fi
    
    cp "$template" "$output"
    
    # 替换变量
    for var in "${vars[@]}"; do
        local key=$(echo "$var" | cut -d'=' -f1)
        local value=$(echo "$var" | cut -d'=' -f2-)
        sed -i "s|\${$key}|$value|g" "$output"
        sed -i "s|{{$key}}|$value|g" "$output"
    done
    
    log_success "配置文件生成完成: $output"
}

# JSON解析工具
parse_json() {
    local json_file=$1
    local key=$2
    
    if command_exists jq; then
        jq -r ".$key" "$json_file" 2>/dev/null
    else
        # 简单的JSON解析 (仅支持简单键值对)
        grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$json_file" | \
        cut -d'"' -f4
    fi
}

# 发送通知
send_notification() {
    local title=$1
    local message=$2
    local webhook_url=${WEBHOOK_URL:-}
    
    if [ -n "$webhook_url" ]; then
        local payload="{\"title\":\"$title\",\"message\":\"$message\",\"timestamp\":\"$(date)\"}"
        curl -s -X POST -H "Content-Type: application/json" -d "$payload" "$webhook_url" >/dev/null || true
    fi
    
    # 也可以记录到系统日志
    logger -t "pt-docker" "$title: $message" 2>/dev/null || true
}

# 清理临时文件
cleanup_temp() {
    local temp_dirs=("/tmp/pt-docker-*" "/var/tmp/pt-docker-*")
    
    log_info "清理临时文件..."
    
    for pattern in "${temp_dirs[@]}"; do
        for dir in $pattern; do
            if [ -d "$dir" ]; then
                rm -rf "$dir"
                log_debug "删除临时目录: $dir"
            fi
        done
    done
}

# 设置清理陷阱
setup_cleanup_trap() {
    trap cleanup_temp EXIT INT TERM
}

# 检查网络连接
check_network() {
    local test_hosts=("8.8.8.8" "1.1.1.1" "114.114.114.114")
    
    for host in "${test_hosts[@]}"; do
        if ping -c 1 -W 3 "$host" >/dev/null 2>&1; then
            log_info "网络连接正常"
            return 0
        fi
    done
    
    log_error "网络连接异常"
    return 1
}

# 检查DNS解析
check_dns() {
    local test_domains=("github.com" "docker.io" "google.com")
    
    for domain in "${test_domains[@]}"; do
        if nslookup "$domain" >/dev/null 2>&1; then
            log_info "DNS解析正常"
            return 0
        fi
    done
    
    log_error "DNS解析异常"
    return 1
}

# 优化系统参数
optimize_system() {
    log_info "优化系统参数..."
    
    # 调整文件描述符限制
    if [ -f /etc/security/limits.conf ]; then
        if ! grep -q "* soft nofile 65536" /etc/security/limits.conf; then
            echo "* soft nofile 65536" >> /etc/security/limits.conf
            echo "* hard nofile 65536" >> /etc/security/limits.conf
        fi
    fi
    
    # 调整内核参数
    if [ -f /etc/sysctl.conf ]; then
        local sysctl_settings=(
            "net.core.somaxconn=65535"
            "net.ipv4.tcp_max_syn_backlog=65535"
            "net.core.netdev_max_backlog=32768"
            "net.ipv4.tcp_timestamps=0"
            "net.ipv4.tcp_synack_retries=2"
            "net.ipv4.tcp_syn_retries=2"
            "net.ipv4.tcp_tw_recycle=1"
            "net.ipv4.tcp_tw_reuse=1"
            "net.ipv4.tcp_mem=94500000 915000000 927000000"
            "net.ipv4.tcp_max_orphans=3276800"
            "vm.swappiness=10"
        )
        
        for setting in "${sysctl_settings[@]}"; do
            local key=$(echo "$setting" | cut -d'=' -f1)
            if ! grep -q "^$key" /etc/sysctl.conf; then
                echo "$setting" >> /etc/sysctl.conf
            fi
        done
        
        sysctl -p >/dev/null 2>&1 || true
    fi
    
    log_success "系统参数优化完成"
}

# 检查并创建用户
create_user() {
    local username=$1
    local uid=${2:-1000}
    local gid=${3:-1000}
    
    if ! id "$username" >/dev/null 2>&1; then
        log_info "创建用户: $username"
        
        # 创建组
        if ! getent group "$username" >/dev/null 2>&1; then
            groupadd -g "$gid" "$username" 2>/dev/null || true
        fi
        
        # 创建用户
        useradd -u "$uid" -g "$gid" -m -s /bin/bash "$username" 2>/dev/null || true
        
        log_success "用户创建完成: $username"
    else
        log_info "用户已存在: $username"
    fi
}

# 设置定时任务
setup_cron() {
    local schedule=$1
    local command=$2
    local user=${3:-root}
    
    log_info "设置定时任务: $schedule $command"
    
    # 检查是否已存在相同的任务
    if crontab -u "$user" -l 2>/dev/null | grep -F "$command" >/dev/null; then
        log_info "定时任务已存在"
        return 0
    fi
    
    # 添加新任务
    (crontab -u "$user" -l 2>/dev/null; echo "$schedule $command") | crontab -u "$user" -
    
    log_success "定时任务设置完成"
}

# 检查Docker环境
check_docker_env() {
    if ! command_exists docker; then
        log_error "Docker未安装"
        return 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker服务未运行"
        return 1
    fi
    
    if ! command_exists docker-compose; then
        log_error "Docker Compose未安装"
        return 1
    fi
    
    log_info "Docker环境检查通过"
    return 0
}

# 等待容器就绪
wait_for_container() {
    local container_name=$1
    local timeout=${2:-60}
    local count=0
    
    log_info "等待容器启动: $container_name"
    
    while [ $count -lt $timeout ]; do
        if docker ps | grep -q "$container_name.*Up"; then
            log_success "容器已启动: $container_name"
            return 0
        fi
        sleep 1
        ((count++))
        
        # 显示进度
        if [ $((count % 5)) -eq 0 ]; then
            echo -n "."
        fi
    done
    
    echo ""
    log_error "等待容器启动超时: $container_name"
    return 1
}

# 检查容器健康状态
check_container_health() {
    local container_name=$1
    
    local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null)
    
    case $health_status in
        "healthy")
            log_info "容器健康状态: $container_name - 健康"
            return 0
            ;;
        "unhealthy")
            log_warn "容器健康状态: $container_name - 不健康"
            return 1
            ;;
        "starting")
            log_info "容器健康状态: $container_name - 启动中"
            return 2
            ;;
        *)
            log_info "容器健康状态: $container_name - 无健康检查"
            return 3
            ;;
    esac
}

# 重试执行函数
retry_command() {
    local max_attempts=$1
    local delay=$2
    shift 2
    local command=("$@")
    
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        log_debug "执行命令 (尝试 $attempt/$max_attempts): ${command[*]}"
        
        if "${command[@]}"; then
            return 0
        else
            if [ $attempt -lt $max_attempts ]; then
                log_warn "命令执行失败，${delay}秒后重试..."
                sleep "$delay"
            fi
        fi
        
        ((attempt++))
    done
    
    log_error "命令执行失败，已达到最大重试次数"
    return 1
}

# 显示横幅
show_banner() {
    local title=$1
    local width=${2:-60}
    local char=${3:-"="}
    
    local title_length=${#title}
    local padding=$(( (width - title_length - 2) / 2 ))
    
    # 上边框
    printf "%*s\n" $width | tr ' ' "$char"
    
    # 标题行
    printf "%c%*s%s%*s%c\n" "$char" $padding "" "$title" $padding "" "$char"
    
    # 下边框
    printf "%*s\n" $width | tr ' ' "$char"
}

# 显示表格
show_table() {
    local -n data=$1
    local headers=("${@:2}")
    
    # 计算列宽
    local -a col_widths=()
    for i in "${!headers[@]}"; do
        local max_width=${#headers[$i]}
        for row in "${data[@]}"; do
            local -a fields=($row)
            if [ ${#fields[$i]} -gt $max_width ]; then
                max_width=${#fields[$i]}
            fi
        done
        col_widths[$i]=$max_width
    done
    
    # 打印表头
    printf "+"
    for width in "${col_widths[@]}"; do
        printf "%*s+" $((width + 2)) | tr ' ' '-'
    done
    printf "\n"
    
    printf "|"
    for i in "${!headers[@]}"; do
        printf " %-*s |" "${col_widths[$i]}" "${headers[$i]}"
    done
    printf "\n"
    
    printf "+"
    for width in "${col_widths[@]}"; do
        printf "%*s+" $((width + 2)) | tr ' ' '-'
    done
    printf "\n"
    
    # 打印数据行
    for row in "${data[@]}"; do
        local -a fields=($row)
        printf "|"
        for i in "${!fields[@]}"; do
            printf " %-*s |" "${col_widths[$i]}" "${fields[$i]}"
        done
        printf "\n"
    done
    
    printf "+"
    for width in "${col_widths[@]}"; do
        printf "%*s+" $((width + 2)) | tr ' ' '-'
    done
    printf "\n"
}

# 主函数 - 用于测试工具函数
main() {
    local command=$1
    
    case $command in
        "test-system")
            show_banner "系统信息测试"
            get_system_info
            ;;
        "test-network")
            show_banner "网络测试"
            check_network && check_dns
            ;;
        "test-docker")
            show_banner "Docker环境测试"
            check_docker_env
            ;;
        "optimize")
            show_banner "系统优化"
            confirm_action "确认优化系统参数" && optimize_system
            ;;
        "cleanup")
            show_banner "清理临时文件"
            cleanup_temp
            ;;
        *)
            echo "工具函数库"
            echo "可用的测试命令:"
            echo "  test-system  - 测试系统信息获取"
            echo "  test-network - 测试网络连接"
            echo "  test-docker  - 测试Docker环境"
            echo "  optimize     - 优化系统参数"
            echo "  cleanup      - 清理临时文件"
            ;;
    esac
}

# 如果直接运行此脚本，执行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
