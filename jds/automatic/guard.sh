#!/usr/bin/env bash
#
# Description: This script exists in a dormant state most of the time and is triggered when needed to automatically start the game server.
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# https://www.honeok.com
# https://github.com/honeok/archive/raw/master/jds/automatic/guard.sh

set \
    -o errexit

readonly version='v0.0.1 (2025.01.10)'

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
_cyan "当前脚本版本: ${version}\n"

readonly guard_pid="/tmp/guard.pid"
readonly project_name="p8_app_server"

# 消息回调开关
readonly enable_stats="0" # 非0为关

script=$(realpath "$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename "${BASH_SOURCE:-$0}")")
script_dir=$(dirname "$(realpath "${script}")")

# 操作系统和权限校验
[ "$(id -ru)" -ne "0" ] && _err_msg "$(_red '需要root用户才能运行！')" && exit 1
os_name=$(grep ^ID= /etc/*release | awk -F'=' '{print $2}' | sed 's/"//g')
[[ "$os_name" != "debian" && "$os_name" != "ubuntu" && "$os_name" != "centos" && "$os_name" != "rhel" && "$os_name" != "rocky" && "$os_name" != "almalinux" ]] && { _err_msg "$(_red '当前操作系统不被支持！')" && exit 1 ;}

trap "cleanup_exit" SIGINT SIGQUIT SIGTERM EXIT

# 安全清屏
clear_screen() {
    if [ -t 1 ]; then
        tput clear 2>/dev/null || echo -e "\033[2J\033[H" || clear
    fi
}

cleanup_exit() {
    [ -f "$guard_pid" ] && rm -f "$guard_pid"

    printf "\n"
    exit 0
}

if [ -f "$guard_pid" ] && kill -0 "$(cat "$guard_pid")" 2>/dev/null; then
    exit 1
fi

echo $$ > "$guard_pid"

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

server_runCheck(){
    local search_server process_Spell
    local running_servers=() # 初始化数组

    search_server=$(find /data/ -maxdepth 1 -type d -name "server*" | sed 's:.*/::' | grep -E '^server[0-9]+$' | sed 's/server//' | sort -n)

    # 拼接服务器组校验是否正在运行
    for run_num in $search_server; do
        process_Spell="/data/server${run_num}/game/${project_name}"

        if pgrep -f "${process_Spell}" >/dev/null 2>&1; then
            running_servers+=("${run_num}")
        fi
    done

    # 检查是否有运行中的服务器
    if [ ${#running_servers[@]} -eq 0 ]; then
        _err_msg "$(_red '没有检测到正在运行的服务器')"
        exit 1
    fi

    # shellcheck disable=SC2034
    # 将运行中的服务器编号输出到server_range
    server_range=$(printf "%s\n" "${running_servers[@]}" | sort -n)
}

