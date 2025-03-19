#!/usr/bin/env bash
#
# Description: server backend resident daemon for monitoring and management.
#
# Copyright (C) 2024 - 2025 honeok <honeok@duck.com>
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

# 当前脚本版本号
readonly version='v0.1.2 (2025.03.18)'

# 各变量默认值
process_pid='/tmp/process.pid'
LOG_DIR='/data/logbak'
WORK_DIR='/data/tool'
APP_NAME='p8_app_server'
UA_BROWSER="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36"
readonly process_pid LOG_DIR WORK_DIR APP_NAME UA_BROWSER

if [ -f "$process_pid" ] && kill -0 "$(cat "$process_pid")" 2>/dev/null; then
    echo 'The script is running, please do not repeat the operation!' && exit 1
fi

echo $$ > "$process_pid"

send_message() {
    local event="$1"
    local cloudflare_api country ipv4_address cur_time os_info cpu_arch

    # 备用 www.qualcomm.cn
    cloudflare_api='www.garmin.com.cn'
    country=$(curl -A "$UA_BROWSER" -fskL -m 3 -4 "https://$cloudflare_api/cdn-cgi/trace" | grep -i '^loc=' | cut -d'=' -f2 | xargs)
    ipv4_address=$(curl -A "$UA_BROWSER" -fskL -m 3 -4 "https://$cloudflare_api/cdn-cgi/trace" | grep -i '^ip=' | cut -d'=' -f2 | xargs)
    cur_time=$(date -d @$(($(curl -fskL -m 3 https://acs.m.taobao.com/gw/mtop.common.getTimestamp/ | awk -F'"t":"' '{print $2}' | cut -d '"' -f1) / 1000)) +"%F %T" ||
        date -u '+%Y-%m-%d %H:%M:%S' -d '+8 hours')
    os_info=$(grep "^PRETTY_NAME=" /etc/*-release | cut -d '"' -f 2 | sed 's/ (.*)//')
    cpu_arch=$(uname -m 2>/dev/null || lscpu | awk -F ': +' '/Architecture/{print $2}')

    curl -fskL -X POST "https://api.honeok.com/api/log" \
        -H "Content-Type: application/json" \
        -d "{\"action\":\"$event $ipv4_address\",\"timestamp\":\"$cur_time\",\"country\":\"$country\",\"os_info\":\"$os_info\",\"cpu_arch\":\"$cpu_arch\"}" >/dev/null 2>&1 &
}

pre_check() {
    [ -t 1 ] && tput clear 2>/dev/null || echo -e "\033[2J\033[H" || clear
    if [ "$(id -ru)" -ne "0" ] || [ "$EUID" -ne "0" ]; then
        echo 'This script must be run as root!' && exit 1
    fi
    if [ "$(ps -p $$ -o comm=)" != "bash" ] || readlink /proc/$$/exe | grep -q "dash"; then
        echo 'This script requires Bash as the shell interpreter!' && exit 1
    fi
    [ ! -d "$LOG_DIR" ] && mkdir -p "$LOG_DIR"
    [ ! -d "$WORK_DIR" ] && mkdir -p "$WORK_DIR"
    [ -t 1 ] && echo -e "Current script version: $version , Daemon process started. \xe2\x9c\x93"
}

# independent logic called by a function
check_server() {
    local server_name="$1"
    local server_dir="$2"

    if ! pgrep -f "$server_dir/$APP_NAME" >/dev/null 2>&1; then
        cd "$server_dir" || return
        [ -f nohup.txt ] && mv -f nohup.txt "$LOG_DIR/nohup_${server_name}_$(date -u '+%Y-%m-%d_%H:%M:%S' -d '+8 hours').txt"
        ./server.sh start &
        send_message "$server_name Restart" &
        echo "$(date -u '+%Y-%m-%d %H:%M:%S' -d '+8 hours') [ERROR] $server_name Restart" >> "$WORK_DIR/dump.txt" &
    else
        echo "$(date -u '+%Y-%m-%d %H:%M:%S' -d '+8 hours') [INFO] $server_name Running" >> "$WORK_DIR/control.txt" &
    fi
}

entrance_check() {
    check_server "gate" "/data/server/gate"
    sleep 3s
    check_server "login" "/data/server/login"
    sleep 3s
}

center_check() {
    local base_path='/data/center'
    local global_server=()
    local zk_server=()
    while IFS='' read -r row; do global_server+=("$row"); done < <(find "$base_path" -maxdepth 1 -type d -name "global*[0-9]" -printf "%f\n" | sed 's/global//' | sort -n)
    while IFS='' read -r row; do zk_server+=("$row"); done < <(find "$base_path" -maxdepth 1 -type d -name "zk*[0-9]" -printf "%f\n" | sed 's/zk//' | sort -n)

    if [ "${#global_server[@]}" -eq 0 ] || [ "${#zk_server[@]}" -eq 0 ]; then return; fi
    for num in "${global_server[@]}"; do
        server_name="global$num"
        server_dir="$base_path/$server_name"
        check_server "$server_name" "$server_dir"
        sleep 3s
    done
    for num in "${zk_server[@]}"; do
        server_name="zk$num"
        server_dir="$base_path/$server_name"
        check_server "$server_name" "$server_dir"
        sleep 3s
    done
}

game_check() {
    local game_server=()
    while IFS='' read -r row; do game_server+=("$row"); done < <(find /data -maxdepth 1 -type d -name "server*[0-9]" -printf "%f\n" | sed 's/server//' | sort -n)

    if [ "${#game_server[@]}" -eq 0 ]; then return; fi
    for num in "${game_server[@]}"; do
        server_name="server$num"
        server_dir="/data/$server_name/game"
        check_server "$server_name" "$server_dir"
        sleep 3s
    done
}

log_check() {
    local log_server=()
    while IFS='' read -r row; do log_server+=("$row"); done < <(find /data -maxdepth 1 -type d -name "logserver*[0-9]" -printf "%f\n" | sed 's/logserver//' | sort -n)

    if [ "${#log_server[@]}" -eq 0 ]; then return; fi
    for num in "${log_server[@]}"; do
        server_name="logserver$num"
        server_dir="/data/$server_name"
        check_server "$server_name" "$server_dir"
        sleep 3s
    done
}

cross_check() {
    local cross_server=()
    while IFS='' read -r row; do cross_server+=("$row"); done < <(find /data -maxdepth 1 -type d -name "crossserver*[0-9]" -printf "%f\n" | sed 's/crossserver//' | sort -n)

    if [ "${#cross_server[@]}" -eq 0 ]; then return; fi
    for num in "${cross_server[@]}"; do
        server_name="crossserver$num"
        server_dir="/data/$server_name"
        check_server "$server_name" "$server_dir"
        sleep 3s
    done
}

gm_check() {
    local gm_server=()
    while IFS='' read -r row; do gm_server+=("$row"); done < <(find /data -maxdepth 1 -type d -name "gmserver*[0-9]" -printf "%f\n" | sed 's/gmserver//' | sort -n)

    if [ "${#gm_server[@]}" -eq 0 ]; then return; fi
    for num in "${gm_server[@]}"; do
        server_name="gmserver$num"
        server_dir="/data/$server_name"
        check_server "$server_name" "$server_dir"
        sleep 3s
    done
}

processcontrol() {
    pre_check

    while :; do
        entrance_check
        center_check
        game_check
        log_check
        cross_check
        gm_check
        sleep 5s
    done
}

processcontrol