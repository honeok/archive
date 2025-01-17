#!/usr/bin/env bash
#
# This script is designed to manage and automatically start game servers based on passed server identifiers.
# It can be invoked with a list of server IDs, and it will automatically start the corresponding servers.
# The action is irreversible once executed, so make sure to pass the correct parameters!
#
# Example Usage:
# ./guard.sh 1/2/3/4/5 ...
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

# shellcheck disable=all

set \
    -o errexit \
    -o nounset

readonly version='v0.0.2 (2025.01.17)'

yellow='\033[1;33m'
red='\033[1;31m'
green='\033[1;32m'
cyan='\033[1;36m'
white='\033[0m'

_yellow() { echo -e "${yellow}$*${white}"; }
_red() { echo -e "${red}$*${white}"; }
_green() { echo -e "${green}$*${white}"; }
_cyan() { echo -e "${cyan}$*${white}"; }

_err_msg() { echo -e "\033[41m\033[1m警告${white} $*"; }
_suc_msg() { echo -e "\033[42m\033[1m成功${white} $*"; }

clear
_cyan "当前脚本版本: ${version} 🤖 \n"

# 预定义变量
# https://unix.stackexchange.com/questions/98401/what-does-readonly-mean-or-do
readonly project_name='p8_app_server'
readonly guard_pid='/tmp/guard.pid'
readonly enable_stats='0' # 消息回调开关，非0为关

# https://www.shellcheck.net/wiki/SC2034
# shellcheck disable=SC2034
script=$(realpath "$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename "${BASH_SOURCE:-$0}")")
script_dir=$(dirname "$(realpath "${script}")")

# 操作系统和权限校验
[ "$(id -ru)" -ne "0" ] && _err_msg "$(_red '需要root用户才能运行！')" && exit 1

# Show more info: https://github.com/koalaman/shellcheck/wiki/SC2155
os_name=$(grep "^ID=" /etc/*release | awk -F'=' '{print $2}' | sed 's/"//g')
readonly os_name

if [[ "$os_name" != "debian" && "$os_name" != "ubuntu" && "$os_name" != "centos" && "$os_name" != "rhel" && "$os_name" != "rocky" && "$os_name" != "almalinux" && "$os_name" != "fedora" && "$os_name" != "alinux" && "$os_name" != "opencloudos" ]]; then
    _err_msg "$(_red '当前操作系统不被支持！')"
    exit 1
fi

trap 'rm -f "$guard_pid" >/dev/null 2>&1; exit 0' SIGINT SIGQUIT SIGTERM EXIT

if [ -f "$guard_pid" ] && kill -0 "$(cat "$guard_pid")" 2>/dev/null; then
    exit 1
fi

echo $$ > "$guard_pid"

# 脚本入参校验
if [[ $# -ne 1 || ! "$1" =~ ^[0-9]+$ ]]; then
    exit 1
else
    server_number="$1"
fi

readonly "$server_number"

# 安全清屏
clear_screen() {
    if [ -t 1 ]; then
        tput clear 2>/dev/null || echo -e "\033[2J\033[H" || clear
    fi
}

# 消息回调
send_message() {
    if [ "$enable_stats" -ne "0" ]; then
        return
    fi

    local event="$1"
    local china_time country os_info cpu_arch

    china_time=$(date -d @$(($(curl -sL https://acs.m.taobao.com/gw/mtop.common.getTimestamp/ | awk -F'"t":"' '{print $2}' | cut -d '"' -f1) / 1000)) +"%Y-%m-%d %H:%M:%S")
    country=$(curl -sL --connect-timeout 5 https://ipinfo.io/country || curl -sL -m 10 -A "Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/81.0" "https://dash.cloudflare.com/cdn-cgi/trace" | sed -n 's/.*loc=\([^ ]*\).*/\1/p')
    os_info=$(grep '^PRETTY_NAME=' /etc/*release | cut -d '"' -f 2 | sed 's/ (.*)//')
    cpu_arch=$(uname -m 2>/dev/null || lscpu | awk -F ': +' '/Architecture/{print $2}' || echo "Full Unknown")

    curl -s -X POST "https://api.honeok.com/api/log" \
        -H "Content-Type: application/json" \
        -d "{\"action\":\"$event\",\"timestamp\":\"$china_time\",\"country\":\"$country\",\"os_name\":\"$os_info\",\"cpu_arch\":\"$cpu_arch\"}" >/dev/null 2>&1 & 
}

# 开服所需时间
get_openserver_time() {
    local taobao_timeapi suning_timeapi

    taobao_timeapi=$(date -d @$(($(curl -sL https://acs.m.taobao.com/gw/mtop.common.getTimestamp/ | awk -F'"t":"' '{print $2}' | cut -d '"' -f1) / 1000)) +"%Y-%m-%dT%H:00:00")
    suning_timeapi=$(date -d @$(($(curl -sL https://f.m.suning.com/api/ct.do | awk -F'"currentTime": ' '{print $2}' | cut -d ',' -f1) / 1000)) +"%Y-%m-%dT%H:00:00")

    # 如果淘宝时间有效，则使用淘宝时间
    if [[ -n "$taobao_timeapi" && "$taobao_timeapi" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:00:00$ ]]; then
        open_server_time="$taobao_timeapi"
    # 如果淘宝时间无效，则尝试使用苏宁时间
    elif [[ -n "$suning_timeapi" && "$suning_timeapi" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:00:00$ ]]; then
        open_server_time="$suning_timeapi"
    fi
    # 如果没有成功获取时间，使用当前时间并调整为北京时间(UTC+8)
    if [[ -z "$open_server_time" || ! "$open_server_time" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:00:00$ ]]; then
        open_server_time=$(date -u -d '+8 hours' +"%Y-%m-%dT%H:00:00")
    fi
}

server_runCheck() {
    local search_dir process_Spell
    local running_servers=() # 初始化数组

    search_dir=$(find /data/ -maxdepth 1 -type d -name "server*" | sed 's:.*/::' | grep -E "^server${server_number}$" | sed 's/server//')

    # 拼接服务器组校验是否正在运行
    for run_num in $search_dir; do
        process_Spell="/data/server${run_num}/game/${project_name}"

        if pgrep -f "${process_Spell}" >/dev/null 2>&1; then
            running_servers+=("${run_num}")
        fi
    done

    # 检查是否有运行中的服务器
    if [ ${#running_servers[@]} -eq 0 ]; then
        _err_msg "$(_red '没有检测到正在运行的服务器')"
        send_message "没有检测到正在运行的服务器"
        exit 1
    fi

    # 将运行中的服务器编号输出到server_range
    server_range=$(printf "%s\n" "${running_servers[@]}" | sort -n)
}

