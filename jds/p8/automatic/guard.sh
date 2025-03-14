#!/usr/bin/env bash
#
# This script is designed to manage and automatically start game servers based on passed server identifiers.
# It can be invoked with a list of server IDs, and it will automatically start the corresponding servers.
# The action is irreversible once executed, so make sure to pass the correct parameters!
#
# Example Usage:
# ./guard.sh 1/2/3/4/5 ...
#
# Built from watchdog.sh (version 2)
# The name "guard & watchdog" reflects its role as an automated watchdog,controlling server processes.
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# https://www.honeok.com
# https://github.com/honeok/archive/raw/master/jds/automatic/guard.sh
#      __     __       _____                  
#  __ / / ___/ /  ___ / ___/ ___ _  __ _  ___ 
# / // / / _  /  (_-</ (_ / / _ `/ /  ' \/ -_)
# \___/  \_,_/  /___/\___/  \_,_/ /_/_/_/\__/ 
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 or later.
# See <https://www.gnu.org/licenses/>

set \
    -o nounset

readonly version='v0.1.0 (2025.01.17)'

yellow='\033[93m'
red='\033[31m'
green='\033[92m'
cyan='\033[96m'
white='\033[0m'
_yellow() { echo -e "${yellow}$*${white}"; }
_red() { echo -e "${red}$*${white}"; }
_green() { echo -e "${green}$*${white}"; }
_cyan() { echo -e "${cyan}$*${white}"; }

_err_msg() { echo -e "\033[41m\033[1m警告${white} $*"; }
_suc_msg() { echo -e "\033[42m\033[1m成功${white} $*"; }
_info_msg() { echo -e "\033[43m\033[1;37m提示${white} $*"; }

[ -t 1 ] && tput clear 2>/dev/null || echo -e "\033[2J\033[H" || clear
printf "%-40s\n" "-" | sed 's/\s/-/g'
_cyan "当前脚本版本: ${version} 🤖 \n"

# Pre variables
# Show more info: https://unix.stackexchange.com/questions/98401/what-does-readonly-mean-or-do
readonly project_name='p8_app_server'
readonly guard_pid='/tmp/guard.pid'
readonly enable_stats='0' # Message callback switch, not zero is off

# https://www.shellcheck.net/wiki/SC2034
# shellcheck disable=SC2034
script=$(realpath "$(cd "$(dirname "${BASH_SOURCE:-$0}")" || exit 1; pwd)/$(basename "${BASH_SOURCE:-$0}")")
# shellcheck disable=SC2034
script_dir=$(dirname "$(realpath "${script}")")

# Operating system and permission verification
[ "$(id -ru)" -ne "0" ] && _err_msg "$(_red '需要root用户才能运行！')" && exit 1

# Show more info: https://github.com/koalaman/shellcheck/wiki/SC2155
os_name=$(grep "^ID=" /etc/*release | awk -F'=' '{print $2}' | sed 's/"//g')
readonly os_name

if [[ "$os_name" != "debian" && "$os_name" != "ubuntu" && "$os_name" != "centos" && "$os_name" != "rhel" && "$os_name" != "rocky" && "$os_name" != "almalinux" && "$os_name" != "fedora" && "$os_name" != "alinux" && "$os_name" != "opencloudos" ]]; then
    _err_msg "$(_red '当前操作系统不被支持！')"
    exit 1
fi

#if [ "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" != "/root" ]; then
#    cd /root >/dev/null 2>&1
#fi

trap 'rm -f "$guard_pid" >/dev/null 2>&1; exit 0' SIGINT SIGQUIT SIGTERM EXIT

if [ -f "$guard_pid" ] && kill -0 "$(cat "$guard_pid")" 2>/dev/null; then
    exit 1
fi

echo $$ > "$guard_pid"

# Message callback
send_message() {
    if [ "$enable_stats" -ne "0" ]; then
        return
    fi

    local event="$1"
    local china_time country os_info cpu_arch

    china_time=$(date -d @$(($(curl -fsL https://acs.m.taobao.com/gw/mtop.common.getTimestamp/ | awk -F'"t":"' '{print $2}' | cut -d '"' -f1) / 1000)) +"%Y-%m-%d %H:%M:%S")
    country=$(curl -fsL --connect-timeout 5 https://ipinfo.io/country || curl -fsL -m 10 -A "Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/81.0" "https://dash.cloudflare.com/cdn-cgi/trace" | sed -n 's/.*loc=\([^ ]*\).*/\1/p')
    os_info=$(grep "^PRETTY_NAME=" /etc/*release | cut -d '"' -f 2 | sed 's/ (.*)//')
    cpu_arch=$(uname -m 2>/dev/null || lscpu | awk -F ': +' '/Architecture/{print $2}' || echo "Full Unknown")

    curl -s -X POST "https://api.honeok.com/api/log" \
        -H "Content-Type: application/json" \
        -d "{\"action\":\"$event\",\"timestamp\":\"$china_time\",\"country\":\"$country\",\"os_name\":\"$os_info\",\"cpu_arch\":\"$cpu_arch\"}" >/dev/null 2>&1 & 
}

# Time required for server launch
get_opentime() {
    local taobao_timeapi suning_timeapi

    taobao_timeapi=$(date -d @$(($(curl -sL https://acs.m.taobao.com/gw/mtop.common.getTimestamp/ | awk -F'"t":"' '{print $2}' | cut -d '"' -f1) / 1000)) +"%Y-%m-%dT%H:00:00")
    suning_timeapi=$(date -d @$(($(curl -sL https://f.m.suning.com/api/ct.do | awk -F'"currentTime": ' '{print $2}' | cut -d ',' -f1) / 1000)) +"%Y-%m-%dT%H:00:00")

    if [[ -n "$taobao_timeapi" && "$taobao_timeapi" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:00:00$ ]]; then
        open_server_time="$taobao_timeapi"
    elif [[ -n "$suning_timeapi" && "$suning_timeapi" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:00:00$ ]]; then
        open_server_time="$suning_timeapi"
    fi
    if [[ -z "$open_server_time" || ! "$open_server_time" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:00:00$ ]]; then
        open_server_time=$(date -u -d '+8 hours' +"%Y-%m-%dT%H:00:00")
    fi
}

server_runcheck() {
    local search_Dir process_Spell

    search_Dir=$(find /data/ -maxdepth 1 -type d -name "server*" | sed 's:.*/::' | grep -E "^server${server_number}$" | sed 's/server//')
    process_Spell="/data/server${server_number}/game/${project_name}"

    if "$search_Dir" >/dev/null 2>&1; then
        _err_msg "$(_red "没有检测到Server${server_number}运行目录")"
        send_message "没有检测到Server${server_number}运行目录"
        exit 1
    fi
    if ! pgrep -f "${process_Spell}" >/dev/null 2>&1; then
        _err_msg "$(_red '没有检测到正在运行的服务器！')"
        send_message "没有检测到正在运行的服务器"
        exit 1
    fi
}

# 修改开服时间
opentime_cmd() {
    if ! pgrep -f "/data/server${server_number}/game" >/dev/null 2>&1; then
        exit 1
    fi
    # 进入游戏目录，修改开服时间
    cd "/data/server${server_number}/game" || exit 1
    [ -f lua/config/open_time.lua ] || exit 1
    sed -i "/^\s*open_server_time\s*=/s|\"[^\"]*\"|\"${open_server_time}\"|" lua/config/open_time.lua || exit 1
    grep -q "^ *open_server_time *= *\"${open_server_time}\"" lua/config/open_time.lua || exit 1
    # 检查文件是否在过去1分钟内被修改
    if ! find lua/config/open_time.lua -mmin -1 >/dev/null 2>&1; then
        exit 1;
    fi
    ./server.sh reload || exit 1
}

# 限制注册
limitRegis_cmd() {
    cd /data/server/login || exit 1
    if [ -f etc/limit_create.txt ]; then
        if [ "$server_number" -ne "1" ]; then
            echo "$server_number" >> etc/limit_create.txt
            # 服务器号出现在限制文件中
            # //////
        fi
    fi
}

# 修改白名单放行登录入口
whitelist_cmd() {
    cd /data/server/login || exit 1
    if [ -f etc/white_list.txt ]; then
        # 删除白名单中的服务器号
        sed -i "/^\s*${server_number}\s*$/d" etc/white_list.txt || exit 1
        # 确保服务器号没有再出现在白名单文件中
        ! grep -q "^\s*${server_number}\s*$" etc/white_list.txt || exit 1
        # 检查文件是否在过去1分钟内被修改
        find etc/white_list.txt -mmin -1 >/dev/null 2>&1 || exit 1
    fi
    ./server.sh reload || exit 1
}

standalone_cmd() {
    opentime_cmd
    limitRegis_cmd
    whitelist_cmd
}

# 解析传参参数
if [ "$#" -eq 0 ]; then
    _err_msg "$(_red "脚本被无效的调用！")"
    send_message "脚本被无效的调用"
    exit 1
else
    while [[ "$#" -ge 1 ]]; do
        # Script parameter check
        if [[ "$1" =~ ^[0-9]+$ ]]; then
            server_number="$1"
            get_opentime
            server_runcheck
            standalone_build_cmd
            _suc_msg "$(_green "server${server_number}开服成功")"
            send_message "server${server_number}开服成功"
        else
            _err_msg "$(_red '无效参数，请重新输入！')"
            send_message "无效参数 $1 被传入"
            exit 1
        fi
        shift
    done
fi