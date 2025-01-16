#!/usr/bin/env bash
#
# Description:
# Stops multiple game servers in parallel, with variables designed for Ansible control. 
# The script is scalable to handle large numbers of servers efficiently.
#
# Copyright (C) 2024 - 2025 honeok <honeok@duck.com>
#
# https://www.honeok.com
# https://github.com/honeok/archive/raw/master/jds/game-allstop.sh
#      __     __       _____                  
#  __ / / ___/ /  ___ / ___/ ___ _  __ _  ___ 
# / // / / _  /  (_-</ (_ / / _ `/ /  ' \/ -_)
# \___/  \_,_/  /___/\___/  \_,_/ /_/_/_/\__/ 
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 or later.
# See <https://www.gnu.org/licenses/>

set \
    -o errexit \
    -o nounset

readonly version='v0.1.0 (2025.01.16)'

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
_info_msg() { echo -e "\033[43m\033[1;37m提示${white} $*"; }

clear
_cyan "当前脚本版本: ${version}\n"

# 操作系统和权限校验
[ "$(id -ru)" -ne "0" ] && _err_msg "$(_red '需要root用户才能运行！')" && exit 1

# Show more info: https://github.com/koalaman/shellcheck/wiki/SC2155
os_name=$(grep "^ID=" /etc/*release | awk -F'=' '{print $2}' | sed 's/"//g')
readonly os_name

if [[ "$os_name" != "debian" && "$os_name" != "ubuntu" && "$os_name" != "centos" && "$os_name" != "rhel" && "$os_name" != "rocky" && "$os_name" != "almalinux" && "$os_name" != "tencentos" && "$os_name" != "alinux" && "$os_name" != "opencloudos" ]]; then
    _err_msg "$(_red '当前操作系统不被支持！')"
    exit 1
fi

# 预定义变量
readonly project_name='p8_app_server'
readonly script_workdir='/data/tool'
readonly gamestop_pid='/tmp/gamestop.pid'

# 捕获终止信号并优雅退出
trap 'rm -f "$gamestop_pid" >/dev/null 2>&1; exit 0' SIGINT SIGQUIT SIGTERM EXIT

if [ -f "$gamestop_pid" ] && kill -0 "$(cat "$gamestop_pid")" 2>/dev/null; then
    exit 1
fi

# 将当前进程写入PID防止并发执行导致冲突
echo $$ > "$gamestop_pid"

end_of() {
    _yellow "按任意键继续"
    read -n 1 -s -r -p ""
}

entranceserver_Runcheck() {
    local entrances=(gate login)

    for entra in "${entrances[@]}"; do
        if ! pgrep -f "/data/server/${entra}/${project_name}" >/dev/null 2>&1; then
            # gate 和 login 检测到未运行只输出警告
            _err_msg "$(_red "${entra} 未检测到运行")"
        fi
    done
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

    # 将运行中的服务器编号输出到server_range变量
    server_range=$(printf "%s\n" "${running_servers[@]}" | sort -n)
}

# 停止服务器守护进程
daemon_stop() {
    cd "$script_workdir" || {
        _err_msg "$(_red "无法进入目录：${script_workdir}")"
        exit 1
    }

    if pgrep -f processcontrol-allserver.sh >/dev/null 2>&1; then
        pkill -9 -f processcontrol-allserver.sh 1>/dev/null
        [ -f "control.txt" ] && : > control.txt
        [ -f "dump.txt" ] && : > dump.txt
        _suc_msg "$(_green 'processcontrol进程已终止文件已清空')"
    else
        _info_msg "$(_yellow 'processcontrol进程未运行无需终止')"
    fi
}

# 停止服务器入口 gate 和 login
entranceserver_stop() {
    cd /data/server/login || { 
        _err_msg "$(_red 'login服务器路径错误')" && exit 1
    }

    if ./server.sh stop; then
        _suc_msg "$(_green 'login服务器已停止')"
    fi

    cd /data/server/gate || { 
        _err_msg "$(_red 'gate服务器路径错误')" && exit 1
    }

    if ./server.sh stop; then
        sleep 60
        _suc_msg "$(_green 'gate服务器已停止')"
    fi
}

gameserver_stop() {
    if [ -n "$server_range" ]; then
        for server_num in $server_range; do
            (
                if [ ! -d "/data/server$server_num/game" ]; then
                    _err_msg "$(_red "server${server_num}路径不存在，子进程已退出")"
                    exit 1 # 子进程退出 防止继续执行
                fi

                cd "/data/server$server_num/game" 2>/dev/null || { _err_msg "$(_red "server${server_num}路径错误")" && exit 1; }

                _yellow "正在处理server${server_num}"
                ./server.sh flush
                sleep 60
                ./server.sh stop
            ) &
        done

        wait # 等待并行任务

        _suc_msg "$(_green '所有game服务器已完成flush和stop操作！')"
    else
        _err_msg "$(_red '服务器编号为空无法执行后续操作')"
        exit 1
    fi
}

standalone_stop() {
    entranceserver_Runcheck
    gameserver_Runcheck
    daemon_stop
    entranceserver_stop
    gameserver_stop
}

# 解析命令行参数
if [ "$#" -eq 0 ]; then
    _info_msg "$(_red "当前为 ${project_name} 的停服操作，确认后按任意键继续")"
    end_of
    standalone_stop
    exit 0
else
    while [[ "$#" -ge 1 ]]; do
        case "$1" in
            -at | --allserver-stop)
                # 所有服务器并行关闭
                shift
                standalone_stop
                ;;
            -es | --entrance-stop)
                # 仅关闭登录入口
                shift
                entranceserver_Runcheck
                daemon_stop
                entranceserver_stop
                ;;
            -gs | --game-stop)
                # 仅关闭游戏服务器
                shift
                gameserver_Runcheck
                daemon_stop
                gameserver_stop
                ;;
            *)
                _err_msg "$(_red '无效选项，请重新输入！')"
                exit 1
                ;;
        esac
    done
fi