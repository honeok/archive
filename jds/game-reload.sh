#!/usr/bin/env bash
#
# Description: Server Rereading.
#
# Copyright (C) 2024 honeok <honeok@duck.com>
# Blog: www.honeok.com
# https://github.com/honeok/archive/blob/master/jds/game-reload.sh

yellow='\033[93m'
red='\033[31m'
green='\033[92m'
white='\033[0m'
_yellow() { echo -e ${yellow}$@${white}; }
_red() { echo -e ${red}$@${white}; }
_green() { echo -e ${green}$@${white}; }

separator() { printf "%-20s\n" "-" | sed 's/\s/-/g'; }

local_update_path="/data/update"
remote_update_source="/data/update/updategame.tar.gz"
center_host="10.46.96.254"
center_passwd="xxxxxxxxxx"

cd $local_update_path || exit 1
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

for i in {1..5}; do
    dest_dir="/data/server$i/game"
    _yellow "正在处理server$i"

    [ ! -d "$dest_dir" ] && _red "目录${dest_dir}不存在，跳过server${i}更新！" && continue

    \cp -fr "$local_update_path/app/"* "$dest_dir/"

    cd "$dest_dir" || exit
    ./server.sh reload
    _green "server${i}更新成功！"
    separator
done