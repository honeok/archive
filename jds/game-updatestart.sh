#!/usr/bin/env bash
#
# Description: Parallel stop game server
#
# Copyright (C) 2024 honeok <honeok@duck.com>
# Blog: www.honeok.com
# https://github.com/honeok/archive/blob/master/jds/game-updatestart.sh

yellow='\033[93m'
red='\033[31m'
green='\033[92m'
white='\033[0m'
_yellow() { echo -e ${yellow}$@${white}; }
_red() { echo -e ${red}$@${white}; }
_green() { echo -e ${green}$@${white}; }

separator() { printf "%-20s\n" "-" | sed 's/\s/-/g'; }

server_range=$(seq 1 5)
local_update_path="/data/update"
remote_update_source="/data/update/updategame.tar.gz"
center_host="10.46.96.254"
center_passwd="xxxxxxxxxx"

cd "$local_update_path" || { _red "无法进入目录 $local_update_path"; exit 1; }
rm -fr *

# 从中心服务器下载最新更新包
if command -v sshpass >/dev/null 2>&1; then
    sshpass -p "$center_passwd" scp -o StrictHostKeyChecking=no "root@$center_host:$remote_update_source" "$local_update_path/" \
        && _green "从中心拉取Updategame.tar.gz成功！" || { _red "下载失败，请检查网络连接或密码"; exit 1; }
else
    _red "sshpass未安装，请先安装sshpass"
    exit 1
fi

tar zxvf "$local_update_path/updategame.tar.gz" \
    && _green "解压成功" || { _red "解压失败"; exit 1; }

for i in $server_range; do
    dest_dir="/data/server$i/game"
    _yellow "正在处理server$i"

    [ ! -d "$dest_dir" ] && _red "目录${dest_dir}不存在，跳过server${i}更新！" && continue

    \cp -fr "$local_update_path/app/"* "$dest_dir/"

    cd "$dest_dir" || exit
    [ -f "nohup.txt" ] && > nohup.txt
    ./server.sh start
    _green "server${i}启动成功！"
    separator
done

# 处理gate和login入口
for entrance in "gate" "login";do
    dest_dir="/data/server/${entrance}"
    _yellow "正在处理${entrance}"

    if [ ! -d "$dest_dir" ]; then
        _red "目录${dest_dir}不存在，跳过${entrance}更新！"
        continue
    fi

    \cp -fr "$local_update_path/app/"* "$dest_dir/"

    cd "$dest_dir" || exit
    [ -f "nohup.txt" ] && > nohup.txt
    ./server.sh start
    _green "${entrance}启动成功！"
    separator
done

# 等待服务器启动
sleep 5s

# 检查并启动processcontrol-allserver
cd /data/tool/
if pgrep -f "processcontrol-allserver.sh" >/dev/null 2>&1; then
    _yellow "processcontrol-allserver守护进程正在运行"
else
    sh processcontrol-allserver.sh >/dev/null 2>&1 &
    _green "processcontrol-allserver守护进程启动成功！"
fi

_green "所有操作完成！"
