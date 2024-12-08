#!/usr/bin/env bash
#
# This script is designed to automate the management of game servers using an API.
# It allows the automatic startup of game servers by passing server identifiers as parameters.
# Please ensure that the parameters are passed correctly, as once executed, the action cannot be undone!
#
# Example Usage:
# ./watchdog.sh 1/2/3/4/5...       # Starts the game server(s) corresponding to the given IDs.
#
# Copyright (C) 2024 honeok <honeok@duck.com>
# Blog: www.honeok.com
# https://github.com/honeok/archive/blob/master/JDSGame/watchdog.sh

game1="10.46.99.216"
game2="127.0.0.1"

os_name=$(grep ^ID= /etc/*release | awk -F'=' '{print $2}' | sed 's/"//g')
[[ "$os_name" != "debian" && "$os_name" != "ubuntu" && "$os_name" != "centos" && "$os_name" != "rocky" && "$os_name" != "alma" ]] && exit 0

[ "$(id -u)" -ne "0" ] && exit 0

if [ "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" != "/root" ]; then
    cd /root >/dev/null 2>&1
fi

watchdog_pid="/tmp/watchdog.pid"
if [ -f "$watchdog_pid" ] && kill -0 $(cat "$watchdog_pid") 2>/dev/null; then
    exit 1
fi
echo $$ > "$watchdog_pid"

trap _exit SIGINT SIGQUIT SIGTERM SIGHUP

_exit() {
    [ -f "$watchdog_pid" ] && rm -f "$watchdog_pid"
    exit 0
}

# 脚本入参校验
if [[ ${#} -ne 1 || ! $1 =~ ^[0-9]+$ ]]; then
    _exit
else
    server_number=$1
fi

# 开服所需时间相关
open_server_time=""
taobao_timeapi=$(date -d @$(($(curl -sL https://acs.m.taobao.com/gw/mtop.common.getTimestamp/ | awk -F'"t":"' '{print $2}' | cut -d '"' -f1) / 1000)) +"%Y-%m-%dT%H:00:00")
suning_timeapi=$(date -d @$(($(curl -sL https://f.m.suning.com/api/ct.do | awk -F'"currentTime": ' '{print $2}' | cut -d ',' -f1) / 1000)) +"%Y-%m-%dT%H:00:00")

for api in "$taobao_timeapi" "$suning_timeapi"; do
    open_server_time=$api  # 将当前API返回的时间赋值给open_server_time

    # 检查时间格式是否有效
    if [[ -n "$open_server_time" && "$open_server_time" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:00:00$ ]]; then
        break
    fi
done

# 如果没有成功获取时间，使用当前时间
if [[ -z "$open_server_time" || ! "$open_server_time" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:00:00$ ]]; then
    open_server_time=$(date -u -d '+8 hours' +"%Y-%m-%dT%H:00:00")  # 使用当前时间并调整为北京时间 (UTC+8)，如果系统时间同步不可用，时间偏差通常不会太大
fi

china_time=$(date -d @$(($(curl -sL https://acs.m.taobao.com/gw/mtop.common.getTimestamp/ | awk -F'"t":"' '{print $2}' | cut -d '"' -f1) / 1000)) +"%Y-%m-%dT%H:%M:%S")
if [ -z $china_time ]; then
    china_time=$(date -d @$(($(curl -sL https://f.m.suning.com/api/ct.do | awk -F'"currentTime": ' '{print $2}' | cut -d ',' -f1) / 1000)) +"%Y-%m-%dT%H:%M:%S")
fi

# echo "xxxxxxxxxxxx" > /root/password.txt && chmod 600 /root/password.txt 只有root用户可以读取该文件
[ -f /root/password.txt ] && [ -s /root/password.txt ] && server_password=$(cat /root/password.txt) || exit 1

# 根据区服编号匹配服务器IP
if (( server_number >= 1 && server_number <= 5 )); then
    server_ip=${game1}
elif (( server_number >= 6 && server_number <= 10 )); then
    server_ip=${game2}
else
    _exit
fi

# API 回调
send_message() {
    local action="$1"
    local country=$(curl -s ipinfo.io/country || echo "unknown")
    local os_info=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d '"' -f 2 | sed 's/ (.*)//')
    local cpu_arch=$(uname -m)

    curl -s -X POST "https://api.honeok.com/api/log" \
        -H "Content-Type: application/json" \
        -d "{\"action\":\"$action\",\"timestamp\":\"${china_time}\",\"country\":\"$country\",\"os_info\":\"$os_info\",\"cpu_arch\":\"$cpu_arch\"}" >/dev/null 2>&1 &
}

if ! command -v sshpass >/dev/null 2>&1 && type -P sshpass >/dev/null 2>&1; then
    if command -v dnf >/dev/null 2>&1; then
        if ! rpm -q epel-release >/dev/null 2>&1; then
            dnf install epel-release -y
        fi
        dnf update -y && dnf install sshpass -y
    elif command -v yum >/dev/null 2>&1; then
        if ! rpm -q epel-release >/dev/null 2>&1; then
            yum install epel-release -y
        fi
        yum update -y && yum install sshpass -y
    elif command -v apt-get >/dev/null 2>&1; then
        apt-get update -y && apt-get install sshpass -y
    else
        _exit
    fi
fi

# 构建远程命令
remote_command="\
# 进入游戏目录，修改开服时间
cd /data/server${server_number}/game || exit 1 && \
[ -f lua/config/profile.lua ] || exit 1 && \
sed -i '/^\s*local open_server_time\s*=/s|\"[^\"]*\"|\"'"$openserver_time"'\"|' lua/config/profile.lua || exit 1 && \
grep -q '^\s*local open_server_time\s*=\s*\"'"$openserver_time"'\"' lua/config/profile.lua || exit 1 && \
# 检查文件是否在过去1分钟内被修改
if ! find lua/config/profile.lua -mmin -1 >/dev/null 2>&1; then exit 1; fi && \
./server.sh reload || exit 1 && \

# 进入登录目录，修改白名单
cd /data/server/login || exit 1 && \
if [ -f etc/white_list.txt ]; then \
    sed -i '/^\s*'"${server_number}"'\s*$/d' etc/white_list.txt || exit 1 && \
    ! grep -q '^\s*'"${server_number}"'\s*$' etc/white_list.txt || exit 1; \
    # 检查文件是否在过去1分钟内被修改
    if ! find etc/white_list.txt -mmin -1 >/dev/null 2>&1; then exit 1; fi && \
else \
    exit 1; \
fi && \
./server.sh reload || exit 1"

# 执行远程命令，三次重试机会
for (( i=1; i<=3; i++ )); do
    # 执行远程命令，捕获错误信息
    output=$(sshpass -p "$server_password" ssh -o StrictHostKeyChecking=no root@$server_ip "$remote_command" 2>&1)
    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        # 如果远程命令执行成功，发送已开服消息
        send_message "[server${server_number}已开服]"
        echo "${china_time} [SUCCESS] server${server_number}已开服" >> watchdog.log 2>&1
        _exit
    fi

    # 如果是最后一次失败，发送失败消息并退出
    if (( i == 3 )); then
        send_message "[server${server_number}开服失败]"
        echo "${china_time} [ERROR] server${server_number}开服失败，错误信息: $output" >> watchdog.log 2>&1
        _exit
    fi

    # 使用指数退避策略增加等待时间
    sleep_time=$(( 5 * i ))  # 逐步增加等待时间：5秒、10秒、15秒
    echo "${china_time} [WARNING] 第${i}次尝试失败，错误信息: ${output}，等待${sleep_time}秒后重试" >> watchdog.log 2>&1

    # 暂停等待后重试
    sleep $sleep_time
done