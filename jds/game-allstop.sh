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

_info_msg() { echo -e "\033[48;5;220m\033[1m提示${white} $*"; }
_err_msg() { echo -e "\033[41m\033[1m警告${white} $*"; }
_suc_msg() { echo -e "\033[42m\033[1m成功${white} $*"; }

server_range=$(find /data/ -maxdepth 1 -type d -name "server*" | sed 's:.*/::' | grep -E '^server[0-9]+$' | sed 's/server//' | sort -n)

clear
cd /data/tool || exit 1
if pgrep -f processcontrol-allserver.sh >/dev/null 2>&1; then
    pkill -9 -f processcontrol-allserver.sh
    [ -f "control.txt" ] && : > control.txt
    [ -f "dump.txt" ] && : > dump.txt
    _suc_msg "$(_green 'processcontrol进程已终止文件已清空')"
else
    _info_msg "$(_red 'processcontrol进程未运行无需终止')"
fi

cd /data/server/login || { _err_msg "$(_red 'login服务器路径错误')" && exit 1; }
./server.sh stop
_suc_msg "$(_green 'login服务器已停止')"

cd /data/server/gate || { _err_msg "$(_red 'gate服务器路径错误')" && exit 1; }
./server.sh stop
sleep 60
_suc_msg "$(_green 'gate服务器已停止')"

for server_num in $server_range; do
    (
        if [ ! -d "/data/server$server_num/game" ]; then
            _err_msg "$(_red "server${server_num}不存在，子进程已退出")"
            exit 1 # 子进程中的退出，防止继续执行
        fi

        cd "/data/server$server_num/game" 2>/dev/null || { _err_msg "$(_red "server${server_num}路径错误")" && exit 1; }

        _yellow "正在处理server$server_num"
        ./server.sh flush
        sleep 60
        ./server.sh stop
    ) &
done
wait # 等待并行任务

_suc_msg "$(_green '所有game服务器已完成flush和stop操作')"