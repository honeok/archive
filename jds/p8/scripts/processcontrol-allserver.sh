#!/usr/bin/env bash
#
# Description: server backend resident daemon for monitoring and management.
#
# Copyright (C) 2024 - 2025 honeok <honeok@duck.com>
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

# https://github.com/koalaman/shellcheck/wiki/SC2207
# shellcheck disable=SC2207

readonly version='v0.1.1 (2025.03.06)'

readonly process_pid='/tmp/process.pid'
readonly logDir='/data/logbak'
readonly workDir='/data/tool'
readonly app_name='p8_app_server'

if [ -f "$process_pid" ] && kill -0 "$(cat "$process_pid")" 2>/dev/null; then
    echo 'The script is running, please do not repeat the operation!' && exit 1
fi

echo $$ > "$process_pid"

_exit() {
    [ -f "$process_pid" ] && rm -f "$process_pid"
}

trap '_exit' SIGINT SIGQUIT SIGTERM EXIT

# api callback
send_message() {
    local event="$1"
    local country os_info cpu_arch

    country=$(curl -fskL -m 3 -4 "https://www.qualcomm.cn/cdn-cgi/trace" | grep -i '^loc=' | cut -d'=' -f2 | xargs)
    public_ip=$(curl -fskL -m 3 -4 "https://www.qualcomm.cn/cdn-cgi/trace" | grep -i '^ip=' | cut -d'=' -f2 | xargs)
    os_info=$(grep "^PRETTY_NAME=" /etc/*-release | cut -d '"' -f 2 | sed 's/ (.*)//')
    cpu_arch=$(uname -m)
    readonly country os_info cpu_arch

    curl -fskL -X POST "https://api.honeok.com/api/log" \
        -H "Content-Type: application/json" \
        -d "{\"action\":\"$event $public_ip\",\"timestamp\":\"$(date -u '+%Y-%m-%d %H:%M:%S' -d '+8 hours')\",\"country\":\"$country\",\"os_info\":\"$os_info\",\"cpu_arch\":\"$cpu_arch\"}" >/dev/null 2>&1 &
}

pre_check() {
    [ -t 1 ] && tput clear 2>/dev/null || echo -e "\033[2J\033[H" || clear
    if [ "$(id -ru)" -ne "0" ] || [ "$EUID" -ne "0" ]; then
        echo 'This script must be run as root!' && exit 1
    fi
    if [ "$(ps -p $$ -o comm=)" != "bash" ] || readlink /proc/$$/exe | grep -q "dash"; then
        echo 'This script requires Bash as the shell interpreter!' && exit 1
    fi
    [ ! -d "$logDir" ] && mkdir -p "$logDir"
    [ ! -d "$workDir" ] && mkdir -p "$workDir"
    [ -t 1 ] && echo -e "Current script version: $version , Daemon process started. \xe2\x9c\x93"
}

# independent logic called by a function
check_server() {
    local server_name="$1"
    local server_dir="$2"

    if ! pgrep -f "$server_dir/$app_name" >/dev/null 2>&1; then
        cd "$server_dir" || return
        [ -f nohup.txt ] && mv -f nohup.txt "$logDir/nohup_${server_name}_$(date -u '+%Y-%m-%d_%H:%M:%S' -d '+8 hours').txt"
        ./server.sh start &
        send_message "$server_name Restart"
        echo "$(date -u '+%Y-%m-%d %H:%M:%S' -d '+8 hours') [ERROR] $server_name Restart" >> "$workDir/dump.txt" &
    else
        echo "$(date -u '+%Y-%m-%d %H:%M:%S' -d '+8 hours') [INFO] $server_name Running" >> "$workDir/control.txt" &
    fi
}

entrance_check() {
    check_server "gate" "/data/server/gate"
    sleep 3s
    check_server "login" "/data/server/login"
    sleep 3s
}

center_check() {
    local base_path global_server zk_server
    global_server=($(find /data/center -maxdepth 1 -type d -name "global*[0-9]" | sed 's:.*/global::' | sort -n | awk '{if(NR>1)printf " ";printf "%s", $0}'))
    zk_server=($(find /data/center -maxdepth 1 -type d -name "zk*[0-9]" | sed 's:.*/zk::' | sort -n | awk '{if(NR>1)printf " ";printf "%s", $0}'))
    base_path='/data/center'

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
    local game_server
    game_server=($(find /data -maxdepth 1 -type d -name "server*[0-9]" | sed 's:.*/server::' | sort -n | awk '{if(NR>1)printf " ";printf "%s", $0}'))

    if [ "${#game_server[@]}" -eq 0 ]; then return; fi
    for num in "${game_server[@]}"; do
        server_name="server$num"
        server_dir="/data/$server_name/game"
        check_server "$server_name" "$server_dir"
        sleep 3s
    done
}

log_check() {
    local log_server
    log_server=($(find /data -maxdepth 1 -type d -name "logserver*[0-9]" | sed 's:.*/logserver::' | sort -n | awk '{if(NR>1)printf " ";printf "%s", $0}'))

    if [ "${#log_server[@]}" -eq 0 ]; then return; fi
    for num in "${log_server[@]}"; do
        server_name="logserver$num"
        server_dir="/data/$server_name"
        check_server "$server_name" "$server_dir"
        sleep 3s
    done
}

cross_check() {
    local cross_server
    cross_server=($(find /data -maxdepth 1 -type d -name "crossserver*[0-9]" | sed 's:.*/crossserver::' | sort -n | awk '{if(NR>1)printf " ";printf "%s", $0}'))

    if [ "${#cross_server[@]}" -eq 0 ]; then return; fi
    for num in "${cross_server[@]}"; do
        server_name="crossserver$num"
        server_dir="/data/$server_name"
        check_server "$server_name" "$server_dir"
        sleep 3s
    done
}

gm_check() {
    local gm_server
    gm_server=($(find /data -maxdepth 1 -type d -name "gmserver*[0-9]" | sed 's:.*/gmserver::' | sort -n | awk '{if(NR>1)printf " ";printf "%s", $0}'))

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