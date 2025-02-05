#!/usr/bin/env bash
#
# Description: Automatically determines the server path and reloads configurations.
#
# Copyright (C) 2024 - 2025 honeok <honeok@duck.com>
#
# https://github.com/honeok/archive/raw/master/jds/p8/game-reload.sh
#      __     __       _____                  
#  __ / / ___/ /  ___ / ___/ ___ _  __ _  ___ 
# / // / / _  /  (_-</ (_ / / _ `/ /  ' \/ -_)
# \___/  \_,_/  /___/\___/  \_,_/ /_/_/_/\__/ 
#                                             
# License Information:
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License, version 3 or later.
#
# This program is distributed WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <https://www.gnu.org/licenses/>.

set \
    -o errexit \
    -o nounset

readonly version='v0.1.7 (2025.02.05)'

yellow='\033[93m'
red='\033[31m'
green='\033[92m'
white='\033[0m'
_yellow() { echo -e "${yellow}$*${white}"; }
_red() { echo -e "${red}$*${white}"; }
_green() { echo -e "${green}$*${white}"; }

_err_msg() { echo -e "\033[41m\033[1m警告${white} $*"; }
_suc_msg() { echo -e "\033[42m\033[1m成功${white} $*"; }
_info_msg() { echo -e "\033[43m\033[1;37m提示${white} $*"; }

short_separator() { printf "%-20s\n" "-" | sed 's/\s/-/g'; }

export DEBIAN_FRONTEND=noninteractive

clear
_yellow "当前脚本版本: ${version} 🛠️ \n"

# 预定义变量
readonly project_name='p8_app_server'
readonly gamereload_pid='/tmp/gamereload.pid'
readonly local_update_dir='/data/update'
readonly remote_update_file='/data/update/updategame.tar.gz'
readonly update_host='10.46.99.186'

# 操作系统和权限校验
if [ "$(id -ru)" -ne "0" ]; then
    _err_msg "$(_red '需要root用户才能运行！')" && exit 1
fi

# https://github.com/koalaman/shellcheck/wiki/SC2155
os_name=$(grep "^ID=" /etc/*release | awk -F'=' '{print $2}' | sed 's/"//g')
readonly os_name

if [[ "$os_name" != "debian" && "$os_name" != "ubuntu" && "$os_name" != "centos" && "$os_name" != "rhel" && "$os_name" != "rocky" && "$os_name" != "almalinux" && "$os_name" != "fedora" && "$os_name" != "alinux" && "$os_name" != "opencloudos" ]]; then
    _err_msg "$(_red '当前操作系统不被支持！')"
    exit 1
fi

# 捕获终止信号并优雅退出
trap 'rm -f "$gamereload_pid" >/dev/null 2>&1; exit 0' SIGINT SIGQUIT SIGTERM EXIT

if [ -f "$gamereload_pid" ] && kill -0 "$(cat "$gamereload_pid")" 2>/dev/null; then
    exit 1
fi

# 将当前进程写入PID防止并发执行导致冲突
echo $$ > "$gamereload_pid"

getserver_passwd() {
    # 获取服务器密码
    # usage: echo "xxxxxxxxxxxx" > "$HOME/password.txt" && chmod 600 "$HOME/password.txt"

    if [ ! -f "$HOME/password.txt" ] || [ ! -s "$HOME/password.txt" ]; then
        _red "密码文件不存在或为空！"
        exit 1
    fi

    for pass_cmd in "head -n 1 $HOME/password.txt | tr -d '[:space:]'" "awk 'NR==1 {gsub(/^[ \t]+|[ \t]+$/, \"\"); print}' $HOME/password.txt"; do
        update_host_passwd=$(eval "$pass_cmd")

        if [ -n "$update_host_passwd" ]; then
            break
        fi
    done

    if [ -z "$update_host_passwd" ]; then
        _red "无法从文件中获取主机密码，请检查密码文件内容！"
        exit 1
    fi
}

gameserver_Runcheck() {
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

    # 将运行中的服务器编号输出到server_ranges变量
    server_ranges=$(printf "%s\n" "${running_servers[@]}" | sort -n)
}

check_cmd() {
    if ! command -v sshpass >/dev/null 2>&1 && type -P sshpass >/dev/null 2>&1; then
        if command -v dnf >/dev/null 2>&1; then
            [[ ! $(rpm -q epel-release) ]] && dnf install -y epel-release
            dnf install -y sshpass
        elif command -v yum >/dev/null 2>&1; then
            [[ ! $(rpm -q epel-release) ]] && yum install -y epel-release
            yum install -y sshpass
        elif command -v apt-get >/dev/null 2>&1; then
            apt-get install -y sshpass
        else
            exit 1
        fi
    fi
}

get_Updatefile() {
    cd "$local_update_dir" || { _err_msg "$(_red "无法进入本地更新包解压路径: $local_update_dir")"; exit 1; }
    rm -rf ./*

    if ! sshpass -p "$update_host_passwd" scp -o StrictHostKeyChecking=no -o ConnectTimeout=30 "root@$update_host:$remote_update_file" "$local_update_dir/"; then
        _err_msg "$(_red '下载失败，请检查网络连接或密码')"
        exit 1
    fi
    if [ ! -e "$local_update_dir/updategame.tar.gz" ]; then
        _err_msg "$(_red '更新包未正确下载，请检查！')"
        exit 1
    fi

    _suc_msg "$(_green '从中心拉取updategame.tar.gz成功！')"

    if tar xvf "$local_update_dir/updategame.tar.gz"; then
        _suc_msg "$(_green '解压成功 ✅')"
    else
        _err_msg "$(_red '解压失败')" 
        exit 1
    fi
    printf "\n"
}

exec_reload() {
    # 将server_ranges解析为数组
    read -r -a server_range <<< "$server_ranges"

    if [ "${#server_range[@]}" -gt 0 ]; then
        for server_num in "${server_range[@]}"; do
            reach_dir="/data/server${server_num}/game"

            if [ ! -d "$reach_dir" ]; then
                _info_msg "$(_yellow "目录${reach_dir}不存在，跳过server${server_num}更新！")"
                continue
            fi

            _yellow "正在处理server${server_num}"
            \cp -rf "${local_update_dir}/app/"* "$reach_dir/"
            cd "$reach_dir" || continue

            if ./server.sh reload; then
                _suc_msg "$(_green "server${server_num}更新成功！✅")"
            fi

            short_separator
        done
    else
        _err_msg "$(_red '服务器编号为空无法执行后续操作')"
        exit 1
    fi
}

standalone_reload() {
    getserver_passwd
    gameserver_Runcheck
    check_cmd
    get_Updatefile
    exec_reload
}

standalone_reload