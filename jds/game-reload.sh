#!/usr/bin/env bash
#
# Description: Automatically determines the server path and reloads configurations.
#
# Copyright (C) 2024 honeok <honeok@duck.com>
#
# https://github.com/honeok/archive/raw/master/jds/game-reload.sh

version='v0.0.3 (2024.12.31)'

yellow='\033[93m'
red='\033[31m'
green='\033[92m'
white='\033[0m'
_yellow() { echo -e "${yellow}$*${white}"; }
_red() { echo -e "${red}$*${white}"; }
_green() { echo -e "${green}$*${white}"; }

_info_msg() { echo -e "\033[48;5;220m\033[1m提示${white} $*"; }
_err_msg() { echo -e "\033[41m\033[1m警告${white} $*"; }
_suc_msg() { echo -e "\033[42m\033[1m成功${white} $*"; }

short_separator() { printf "%-20s\n" "-" | sed 's/\s/-/g'; }

export DEBIAN_FRONTEND=noninteractive

server_range=$(find /data/ -maxdepth 1 -type d -name "server*" | sed 's:.*/::' | grep -E '^server[0-9]+$' | sed 's/server//' | sort -n)
reload_pid='/tmp/reload.pid'
local_update_dir='/data/update'
remote_update_file='/data/update/updategame.tar.gz'
update_host='192.168.1.1'

clear
_yellow "当前脚本版本: ${version}"

# 操作系统和权限校验
[ "$(id -ru)" -ne "0" ] && _err_msg "$(_red '需要root用户才能运行！')" && exit 1
os_info=$(grep ^ID= /etc/*release | awk -F'=' '{print $2}' | sed 's/"//g')
[[ "$os_info" != "debian" && "$os_info" != "ubuntu" && "$os_info" != "centos" && "$os_info" != "rhel" && "$os_info" != "rocky" && "$os_info" != "almalinux" ]] && exit 0

trap "cleanup_exit ; echo "" ; exit 0" SIGINT SIGQUIT SIGTERM EXIT

cleanup_exit() {
    [ -f "$reload_pid" ] && rm -f "$reload_pid"
}

if [ -f "$reload_pid" ] && kill -0 "$(cat "$reload_pid")" 2>/dev/null; then
    exit 1
fi
echo $$ > "$reload_pid"

# 检查Server目录
if [ -z "$server_range" ]; then
    _err_msg "$(_red '未找到任何有效的server目录！')"
    cleanup_exit
fi
# 获取服务器密码 usage: echo "xxxxxxxxxxxx" > "$HOME/password.txt" && chmod 600 "$HOME/password.txt"
if [ -f "$HOME/password.txt" ] && [ -s "$HOME/password.txt" ]; then
    update_host_passwd=$(head -n 1 "$HOME/password.txt" | tr -d '[:space:]')
else
    cleanup_exit
fi
if [ -z "$update_host_passwd" ]; then
    update_host_passwd=$(awk 'NR==1 {gsub(/^[ \t]+|[ \t]+$/, ""); print}' "$HOME/password.txt")
fi
if [ -z "$update_host_passwd" ]; then
    cleanup_exit
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

cd "$local_update_dir" || cleanup_exit
rm -rf ./*

if ! sshpass -p "$update_host_passwd" scp -o StrictHostKeyChecking=no -o ConnectTimeout=30 "root@$update_host:$remote_update_file" "$local_update_dir/"; then
    _err_msg "$(_red '下载失败，请检查网络连接或密码')" && cleanup_exit
fi
if [ ! -f "$local_update_dir/updategame.tar.gz" ]; then
    _err_msg "$(_red '更新包未正确下载，请检查！')" && cleanup_exit
fi
_suc_msg "$(_green '从中心拉取updategame.tar.gz成功！')"

if tar zxvf "$local_update_dir/updategame.tar.gz"; then
    _suc_msg "$(_green '解压成功')"
else
    _err_msg "$(_red '解压失败')" 
    cleanup_exit
fi

for server_num in $server_range; do
    reach_dir="/data/server${server_num}/game"

    if [ ! -d "$reach_dir" ]; then
        _info_msg "$(_yellow "目录${reach_dir}不存在，跳过server${server_num}更新！")"
        continue
    fi

    _yellow "正在处理server${server_num}"
    \cp -rf "${local_update_dir}/app/"* "$reach_dir/"
    cd "$reach_dir" || continue
    ./server.sh reload
    _suc_msg "$(_green "server${server_num}更新成功！")"

    short_separator
done