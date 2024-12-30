#!/usr/bin/env bash
#
# This script is designed to automate the management of game servers using an API.
# It allows the automatic startup of game servers by passing server identifiers as parameters.
# Please ensure that the parameters are passed correctly, as once executed, the action cannot be undone!
#
# Example Usage:
# ./watchdog.sh 1/2/3/4/5... # Starts the game server(s) corresponding to the given IDs.
#
# Copyright (C) 2024 honeok <honeok@duck.com>
#
# https://github.com/honeok/archive/raw/master/jds/watchdog.sh

version='v0.0.2 (2024.12.30)'
set -e

yellow='\033[93m'
red='\033[31m'
white='\033[0m'
_yellow() { echo -e "${yellow}$*${white}"; }
_red() { echo -e "${red}$*${white}"; }
_err_msg() { echo -e "\033[41m\033[1m警告${white} $*"; }

export DEBIAN_FRONTEND=noninteractive

watchdog_pid="/tmp/watchdog.pid"
country=""
remote_server_passwd=""
server_number=""
server_ip=""
open_server_time=""

# 操作系统和权限校验
os_info=$(grep ^ID= /etc/*release | awk -F'=' '{print $2}' | sed 's/"//g')
[[ "$os_info" != "debian" && "$os_info" != "ubuntu" && "$os_info" != "centos" && "$os_info" != "rhel" && "$os_info" != "rocky" && "$os_info" != "almalinux" ]] && exit 0
[ "$(id -u)" -ne "0" ] && _err_msg "$(_red '需要root用户才能运行！')" && exit 1

trap "cleanup_exit ; echo "" ; exit 0" SIGINT SIGQUIT SIGTERM EXIT

cleanup_exit() {
    [ -f "$watchdog_pid" ] && rm -f "$watchdog_pid"
}

if [ -f "$watchdog_pid" ] && kill -0 "$(cat "$watchdog_pid")" 2>/dev/null; then
    exit 1
fi
echo $$ > "$watchdog_pid"

if [ "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" != "/root" ]; then
    cd /root >/dev/null 2>&1
fi

geo_check() {
    local cloudflare_api="https://dash.cloudflare.com/cdn-cgi/trace"
    local user_agent="Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/81.0"

    country=$(curl -A "$user_agent" -m 10 -s "$cloudflare_api" | grep -oP 'loc=\K\w+')
    [ -z "$country" ] && _err_msg "$(_red '无法获取服务器所在地区，请检查网络！')" && cleanup_exit
}

geo_check

send_message() {
    local event="$1"
    local cpu_arch
    cpu_arch=$(uname -m 2>/dev/null || lscpu | awk -F ': +' '/Architecture/{print $2}' || echo "Full Unknown")

    curl -s -X POST "https://api.honeok.com/api/log" \
        -H "Content-Type: application/json" \
        -d "{\"action\":\"$event\",\"timestamp\":\"$china_time\",\"country\":\"$country\",\"os_info\":\"$os_info\",\"cpu_arch\":\"$cpu_arch\"}" >/dev/null 2>&1 & 
}

china_time=$(
    if [ "$country" == "CN" ]; then
        # date -d @$(($(curl -sL https://f.m.suning.com/api/ct.do | awk -F'"currentTime": ' '{print $2}' | cut -d ',' -f1) / 1000)) +"%Y-%m-%d %H:%M:%S"
        date -d @$(($(curl -sL https://acs.m.taobao.com/gw/mtop.common.getTimestamp/ | awk -F'"t":"' '{print $2}' | cut -d '"' -f1) / 1000)) +"%Y-%m-%d %H:%M:%S"
    else
        curl -fsL "https://timeapi.io/api/Time/current/zone?timeZone=Asia/Shanghai" | grep -oP '"dateTime":\s*"\K[^"]+' | sed 's/\.[0-9]*//g' | sed 's/T/ /'
    fi
)
[[ -z "$china_time" ]] && china_time=$(date -u -d '+8 hours' +"%Y-%m-%d %H:%M:%S")

# 获取服务器密码 usage: echo "xxxxxxxxxxxx" > "$HOME/password.txt" && chmod 600 "$HOME/password.txt"
if [ -f "$HOME/password.txt" ] && [ -s "$HOME/password.txt" ]; then
    remote_server_passwd=$(head -n 1 "$HOME/password.txt" | tr -d '[:space:]')
else
    cleanup_exit
fi
[ -n "$remote_server_passwd" ] || remote_server_passwd=$(awk 'NR==1 {gsub(/^[ \t]+|[ \t]+$/, ""); print}' "$HOME/password.txt")
[ -n "$remote_server_passwd" ] || cleanup_exit

_yellow "当前脚本版本: ${version}"

# 脚本入参校验
if [[ $# -ne 1 || ! $1 =~ ^[0-9]+$ ]]; then
    cleanup_exit
else
    server_number="$1"
fi

# 服务器IP匹配
declare -A server_ips=(
    ["1,2,3,4,5"]="192.168.1.1"
    ["6,7,8,9,10"]="192.168.1.2"
    ["11,12,13,14,15"]="192.168.1.3"
)

# 查找匹配的服务器IP
for server_range in "${!server_ips[@]}"; do
    if [[ "$server_range" =~ (^|,)$server_number(,|$) ]]; then
        server_ip="${server_ips[$server_range]}"
        break
    fi
done
[[ -z "$server_ip" ]] && cleanup_exit

# 开服所需时间
taobao_timeapi=$(date -d @$(($(curl -sL https://acs.m.taobao.com/gw/mtop.common.getTimestamp/ | awk -F'"t":"' '{print $2}' | cut -d '"' -f1) / 1000)) +"%Y-%m-%dT%H:00:00")
suning_timeapi=$(date -d @$(($(curl -sL https://f.m.suning.com/api/ct.do | awk -F'"currentTime": ' '{print $2}' | cut -d ',' -f1) / 1000)) +"%Y-%m-%dT%H:00:00")

if [[ -n "$taobao_timeapi" && "$taobao_timeapi" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:00:00$ ]]; then
    open_server_time="$taobao_timeapi"
elif [[ -n "$suning_timeapi" && "$suning_timeapi" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:00:00$ ]]; then
    open_server_time="$suning_timeapi"
fi
if [[ -z "$open_server_time" || ! "$open_server_time" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:00:00$ ]]; then
    open_server_time=$(date -u -d '+8 hours' +"%Y-%m-%dT%H:00:00") # 如果没有成功获取时间，使用当前时间并调整为北京时间(UTC+8)，如果系统时间同步不可用时间偏差通常不会太大
fi

if ! command -v sshpass >/dev/null 2>&1 && type -P sshpass >/dev/null 2>&1; then
    if command -v dnf >/dev/null 2>&1; then
        [[ ! $(rpm -q epel-release) ]] && dnf install epel-release -y
        dnf update -y && dnf install sshpass -y
    elif command -v yum >/dev/null 2>&1; then
        [[ ! $(rpm -q epel-release) ]] && yum install epel-release -y
        yum update -y && yum install sshpass -y
    elif command -v apt >/dev/null 2>&1; then
        apt update -y && apt install sshpass -y
    else
        cleanup_exit
    fi
fi

# 远程命令构建
remote_command="\
if ! pgrep -f /data/server${server_number}/game >/dev/null 2>&1; then exit 1; fi && \
# 进入游戏目录，修改开服时间
cd /data/server${server_number}/game || exit 1 && \
[ -f lua/config/open_time.lua ] || exit 1 && \
sed -i '/^\s*open_server_time\s*=/s|\"[^\"]*\"|\"${open_server_time}\"|' lua/config/open_time.lua || exit 1 && \
grep -q \"^\s*open_server_time\s*=\s*\"${open_server_time}\"\" lua/config/open_time.lua || exit 1 && \
# 检查文件是否在过去1分钟内被修改
if ! find lua/config/open_time.lua -mmin -1 >/dev/null 2>&1; then exit 1; fi && \
# 重载游戏服务器
./server.sh reload || exit 1 && \

# 进入登录目录，修改白名单
cd /data/server/login || exit 1 && \
if [ -f etc/white_list.txt ]; then
    # 删除白名单中的当前服务器号
    sed -i '/^\s*${server_number}\s*$/d' etc/white_list.txt || exit 1 && \
    # 确保服务器号没有再出现在白名单文件中
    ! grep -q '^\s*${server_number}\s*$' etc/white_list.txt || exit 1 && \
    # 检查文件是否在过去1分钟内被修改
    find etc/white_list.txt -mmin -1 >/dev/null 2>&1 || exit 1 && \
fi && \
# 重载登录服务器
./server.sh reload || exit 1"

for (( i=1; i<=3; i++ )); do
    # 执行远程命令，连接超时为30秒
    if ! sshpass -p "$remote_server_passwd" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 root@"$server_ip" "$remote_command" 2>&1; then
        if (( i == 3 )); then
            send_message "[server${server_number}开服失败]"
            echo "${china_time} [ERROR] server${server_number}开服失败" >> watchdog.log 2>&1
            cleanup_exit
        fi
        # 指数退避策略增加等待时间
        sleep_time=$(( 5 * i ))
        echo "${china_time} [WARNING] 第${i}次尝试失败，等待${sleep_time}秒后重试" >> watchdog.log 2>&1
        # 暂停等待后重试
        sleep "$sleep_time"
    else
        send_message "[server${server_number}已开服]"
        echo "${china_time} [SUCCESS] server${server_number}已开服" >> watchdog.log 2>&1
        cleanup_exit
    fi
done