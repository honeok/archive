#!/usr/bin/env bash
#
# Description: Adaptively resolves paths and stops multiple servers in parallel.
#
# Copyright (c) 2024 - 2025 honeok <honeok@duck.com>
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

# workflows:
# 1> 入口服停止 (login gate)
# 2> game服停止
# 3> 跨服服务停止
# 4> GM服停止
# 5> 中心服停止 (global and zk)
# 6> 日志服停止

set \
    -o nounset

readonly version='v0.2.1 (2025.03.10)'

red='\033[91m'
green='\033[92m'
yellow='\033[93m'
purple='\033[95m'
cyan='\033[96m'
white='\033[0m'
_red() { echo -e "${red}$*${white}"; }
_green() { echo -e "${green}$*${white}"; }
_yellow() { echo -e "${yellow}$*${white}"; }
_purple() { echo -e "${purple}$*${white}"; }
_cyan() { echo -e "${cyan}$*${white}"; }

_err_msg() { echo -e "\033[41m\033[1mError${white} $*"; }
_suc_msg() { echo -e "\033[42m\033[1mSuccess${white} $*"; }
_info_msg() { echo -e "\033[46m\033[1mTip${white} $*"; }

# 预定义常量
# https://github.com/koalaman/shellcheck/wiki/SC2155
os_name=$(grep "^ID=" /etc/*-release | awk -F'=' '{print $2}' | sed 's/"//g')
stop_pid='/tmp/stop.pid'
workDir='/data/tool'
app_Name='p8_app_server'
readonly os_name stop_pid workDir app_Name

if [ -f "$stop_pid" ] && kill -0 "$(cat "$stop_pid")" 2>/dev/null; then
    _err_msg "$(_red 'The script is running, please do not repeat the operation!')" && exit 1
fi

echo $$ > "$stop_pid"

# 停服任务下发后, 信号捕获后的退出仅删除运行pid, 实际后台停服并行任务并未终止
_exit() {
    local return_value="$?"

    [ -f "$stop_pid" ] && rm -f "$stop_pid"
    exit "$return_value"
}

trap '_exit' SIGINT SIGQUIT SIGTERM EXIT

# 清屏函数
clear_screen() {
    if [ -t 1 ]; then
        tput clear 2>/dev/null || echo -e "\033[2J\033[H" || clear
    fi
}

# 运行校验
pre_check() {
    case "${1:-}" in
        Y|y) : ;;
        *) echo "$(_cyan "当前为 $app_Name 停服") $(_yellow '按任意键继续')"; read -n 1 -s -r -p "" ;;
    esac

    clear_screen
    echo "$(_purple 'Current script version') $(_yellow "$version")"
    if [ "$(id -ru)" -ne "0" ] || [ "$EUID" -ne "0" ]; then
        _err_msg "$(_red 'This script must be run as root!')" && exit 1
    fi
    if [ "$(ps -p $$ -o comm=)" != "bash" ] || readlink /proc/$$/exe | grep -q "dash"; then
        _err_msg "$(_red 'This script requires Bash as the shell interpreter!')" && exit 1
    fi
    if [ "$os_name" != "alinux" ] && [ "$os_name" != "almalinux" ] \
        && [ "$os_name" != "centos" ] && [ "$os_name" != "debian" ] \
        && [ "$os_name" != "fedora" ] && [ "$os_name" != "opencloudos" ] \
        && [ "$os_name" != "opensuse" ] && [ "$os_name" != "rhel" ] \
        && [ "$os_name" != "rocky" ] && [ "$os_name" != "ubuntu" ]; then
        _err_msg "$(_red 'The current operating system is not supported!')" && exit 1
    fi
}

# 统一停止入口
stop_server() {
    local server_name="$1"
    local server_dir="$2"
    local _delay="${3:-60s}" # Default flush delay is 60s

    # 子进程退出防止继续执行
    (
        if ! pgrep -f "$server_dir/$app_Name" >/dev/null 2>&1; then exit 0; fi # 进程存活校验
        cd "$server_dir" || { _err_msg "$(_red "$server_name path error.")" ; exit 1; }
        [ ! -f server.sh ] && { _err_msg "$(_red "server.sh does not exist.")" ; exit 1; }
        [ ! -x server.sh ] && chmod +x server.sh
        ./server.sh flush && sleep "$_delay" && ./server.sh stop
        _suc_msg "$(_green "$server_name The server has stopped.")"
    ) &
}

# 停止守护进程并清空运行日志
daemon_stop() {
    local daemon_file
    daemon_file='processcontrol-allserver.sh'

    if pgrep -f "$daemon_file" >/dev/null 2>&1; then
        pkill -9 -f "$daemon_file" >/dev/null 2>&1
        [ -f "$workDir/control.txt" ] && : > "$workDir/control.txt"
        [ -f "$workDir/dump.txt" ] && : > "$workDir/dump.txt"
        _suc_msg "$(_green "$daemon_file Process terminated, files cleared.")"
    else
        _info_msg "$(_cyan "$daemon_file The process is not running.")"
    fi
}

# 登录入口停止
entrance_stop() {
    if [ ! -d /data/server/login ] || [ ! -d /data/server/gate ]; then return; fi
    stop_server "login" "/data/server/login" "0s" # 0为存盘时间 $3, 无需存盘等待
    wait
    stop_server "gate" "/data/server/gate"
    wait

    _suc_msg "$(_green "Entrance stop success! \xe2\x9c\x93")"
}

# 游戏进程停止
game_stop() {
    local game_server=()
    while IFS='' read -r row; do game_server+=("$row"); done < <(find /data -maxdepth 1 -type d -name "server*[0-9]" -printf "%f\n" | sed 's/server//' | sort -n)

    if [ "${#game_server[@]}" -eq 0 ]; then _info_msg "$(_cyan 'The GameServer list is empty, skip execution.')" && return; fi
    for num in "${game_server[@]}"; do
        server_name="server$num"
        server_dir="/data/$server_name/game"
        stop_server "$server_name" "$server_dir"
    done
    wait
    _suc_msg "$(_green "All GameServer stop success! \xe2\x9c\x93")"
}

# 跨服服务器停止
cross_stop() {
    local cross_server=()
    while IFS='' read -r row; do cross_server+=("$row"); done < <(find /data -maxdepth 1 -type d -name "crossserver*[0-9]" -printf "%f\n" | sed 's/crossserver//' | sort -n)

    if [ "${#cross_server[@]}" -eq 0 ]; then _info_msg "$(_cyan 'The CrossServer list is empty, skip execution.')" && return; fi
    for num in "${cross_server[@]}"; do
        server_name="crossserver$num"
        server_dir="/data/$server_name"
        stop_server "$server_name" "$server_dir"
    done
    wait
    _suc_msg "$(_green "All CrossServer stop success! \xe2\x9c\x93")"
}

# GM服务器停止
gm_stop() {
    local gm_server=()
    while IFS='' read -r row; do gm_server+=("$row"); done < <(find /data -maxdepth 1 -type d -name "gmserver*[0-9]" -printf "%f\n" | sed 's/gmserver//' | sort -n)

    if [ "${#gm_server[@]}" -eq 0 ]; then _info_msg "$(_cyan 'The GMServer list is empty, skip execution.')" && return; fi
    for num in "${gm_server[@]}"; do
        server_name="gmserver$num"
        server_dir="/data/$server_name"
        stop_server "$server_name" "$server_dir"
    done
    wait
    _suc_msg "$(_green "All GMServer stop success! \xe2\x9c\x93")"
}

center_stop() {
    local base_path 
    local global_server=()
    local zk_server=()
    readonly base_path='/data/center'

    if [ ! -d "$base_path" ]; then _info_msg "$(_cyan "The $base_path is empty, skip execution.")" && return; fi
    while IFS='' read -r row; do global_server+=("$row"); done < <(find "$base_path" -maxdepth 1 -type d -name "global*[0-9]" -printf "%f\n" | sed 's/global//' | sort -n)
    while IFS='' read -r row; do zk_server+=("$row"); done < <(find "$base_path" -maxdepth 1 -type d -name "zk*[0-9]" -printf "%f\n" | sed 's/zk//' | sort -n)

    if [ "${#global_server[@]}" -eq 0 ]; then
        _info_msg "$(_cyan 'The GlobalServer list is empty, skip execution.')"
        :
    else
        for num in "${global_server[@]}"; do
            server_name="global$num"
            server_dir="$base_path/$server_name"
            stop_server "$server_name" "$server_dir"
        done
        wait
        _suc_msg "$(_green "All GlobalServer stop success! \xe2\x9c\x93")"
    fi

    # ZK Server无需存盘, 传参$3跳过
    if [ "${#zk_server[@]}" -eq 0 ]; then
        _info_msg "$(_cyan 'The ZKServer list is empty, skip execution.')"
        :
    else
        for num in "${zk_server[@]}"; do
            server_name="zk$num"
            server_dir="$base_path/$server_name"
            stop_server "$server_name" "$server_dir" "0s"
        done
        wait
        _suc_msg "$(_green "All ZKServer stop success! \xe2\x9c\x93")"
    fi
}

log_stop() {
    local log_server=()
    while IFS='' read -r row; do log_server+=("$row"); done < <(find /data -maxdepth 1 -type d -name "logserver*[0-9]" -printf "%f\n" | sed 's/logserver//' | sort -n)

    if [ "${#log_server[@]}" -eq 0 ]; then _info_msg "$(_cyan 'The GMServer list is empty, skip execution.')" && return; fi
    for num in "${log_server[@]}"; do
        server_name="logserver$num"
        server_dir="/data/$server_name"
        stop_server "$server_name" "$server_dir"
    done
    wait
    _suc_msg "$(_green "All LogServer stop success! \xe2\x9c\x93")"
}

stop() {
    pre_check "$@"
    daemon_stop
    entrance_stop
    game_stop
    cross_stop
    gm_stop
    center_stop
    log_stop
}

stop "$@"