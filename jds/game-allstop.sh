#!/usr/bin/env bash
#
# Description: The game server is stopped in parallel.
#
# Copyright (C) 2024 honeok <honeok@duck.com>
#
# https://github.com/honeok/archive/raw/master/jds/game-allstop.sh

yellow='\033[93m'
red='\033[31m'
green='\033[92m'
white='\033[0m'
_yellow() { echo -e "${yellow}$*${white}"; }
_red() { echo -e "${red}$*${white}"; }
_green() { echo -e "${green}$*${white}"; }

server_range=$(seq 1 5)

clear
cd /data/tool || exit 1
if pgrep -f processcontrol-allserver.sh >/dev/null 2>&1; then
    pkill -9 -f processcontrol-allserver.sh
    [ -f "control.txt" ] && : > control.txt
    [ -f "dump.txt" ] && : > dump.txt
    _green "processcontrol进程已终止文件已清空"
else
    _red "processcontrol进程未运行无需终止"
fi

cd /data/server/login/ && ./server.sh stop
cd /data/server/gate/ && ./server.sh stop && sleep 60
_green "login和gate服务器已停止"

for server_num in $server_range; do
    (
        _yellow "正在处理server$server_num"
        cd "/data/server$server_num/game" || continue
        ./server.sh flush
        sleep 60
        ./server.sh stop
    ) &
done
# 等待所有并行操作完成
wait
_green "所有Game服务器已完成flush和stop操作"