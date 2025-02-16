#!/usr/bin/env bash
#
# Description: server backend resident daemon for monitoring and management.
#
# Copyright (C) 2024 - 2025 honeok <honeok@duck.com>
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

readonly version='v0.0.3 (2025.02.01)'

# 预定义变量
logDir='/data/logbak'
app_name='p8_app_server'
base_path='/data/server'
readonly logDir app_name base_path

# 权限校验
if [ "$(id -ru)" -ne "0" ]; then
    echo "需要root用户才能运行！" && exit 1
fi

# 服务器范围
server_range=$(find /data/ -maxdepth 1 -type d -name "server*" | sed 's:.*/::' | grep -E '^server[0-9]+$' | sed 's/server//' | sort -n)

# 日志备份目录校验
[ ! -d "$logDir" ] && mkdir -p "$logDir"

# api回调函数
send_message() {
    local action="$1"
    local country os_info cpu_arch

    country=$(curl -fsL --connect-timeout 5 https://ipinfo.io/country || echo "unknown")
    os_info=$(grep "^PRETTY_NAME=" /etc/*release | cut -d '"' -f 2 | sed 's/ (.*)//')
    cpu_arch=$(uname -m)
    readonly country os_info cpu_arch

    curl -s -X POST "https://api.honeok.com/api/log" \
        -H "Content-Type: application/json" \
        -d "{\"action\":\"$action\",\"timestamp\":\"$(date -u '+%Y-%m-%d %H:%M:%S' -d '+8 hours')\",\"country\":\"$country\",\"os_info\":\"$os_info\",\"cpu_arch\":\"$cpu_arch\"}" >/dev/null 2>&1 &
}

# 服务器运行状态校验
check_server() {
    local server_name=$1
    local server_dir=$2

    if ! pgrep -f "$server_dir/$app_name" >/dev/null 2>&1; then
        cd "$server_dir" || return
        if [ -f nohup.txt ]; then
            cp -f nohup.txt "${logDir}/nohup_${server_name}_$(date -u '+%Y-%m-%d_%H:%M:%S' -d '+8 hours').txt" && rm -f nohup.txt
        fi
        ./server.sh start &
        send_message "[${server_name} Restart]"
        echo "$(date -u '+%Y-%m-%d %H:%M:%S' -d '+8 hours') [ERROR] $server_name Restart" >> /data/tool/dump.txt &
    else
        echo "$(date -u '+%Y-%m-%d %H:%M:%S' -d '+8 hours') [INFO] $server_name Running" >> /data/tool/control.txt &
    fi
}

if [ -z "$server_range" ]; then
    echo "服务器编号为空，无法自适配工作路径！"
    exit 1
fi

# [ -t 1 ] && tput clear 2>/dev/null || echo -e "\033[2J\033[H" || clear
printf "当前脚本版本: %s 💡 \n" "${version}"

while :; do
    # 检查game
    for game_num in $server_range; do
        server_name="server${game_num}"
        server_dir="${base_path}${game_num}/game"
        check_server "${server_name}" "${server_dir}"
        sleep 5s
    done

    # 检查gate
    check_server "gate" "${base_path}/gate"
    sleep 5s

    # 检查login
    check_server "login" "${base_path}/login"

    sleep 10s
done