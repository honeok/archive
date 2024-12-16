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

server_range=$(find /data/ -maxdepth 1 -type d -name "server*" | sed 's:.*/::' | grep -Eo 'server[0-9]+' | grep -Eo '[0-9]+' | sort -n)
local_update_path="/data/update"
remote_update_source="/data/update/updategame.tar.gz"
center_host="10.46.96.254"

# 验证操作系统和权限
os_name=$(grep ^ID= /etc/*release | awk -F'=' '{print $2}' | sed 's/"//g')
[[ "$os_name" != "debian" && "$os_name" != "ubuntu" && "$os_name" != "centos" && "$os_name" != "rocky" && "$os_name" != "alma" ]] && exit 0
[ "$(id -u)" -ne "0" ] && exit 1

# 读取中心服务器密码
# echo "xxxxxxxxxxxx" > /root/password.txt chmod 600 /root/password.txt 只有root用户可以读取该文件
[ -f /root/password.txt ] && [ -s /root/password.txt ] || exit 1
center_passwd=$(cat /root/password.txt)
[ -n "$center_passwd" ] || exit 1

cd $local_update_path || exit 1
rm -fr *

# 从中心服务器下载最新更新包
if ! command -v sshpass >/dev/null 2>&1; then
    if command -v dnf >/dev/null 2>&1; then
        if ! rpm -q epel-release >/dev/null 2>&1; then
            dnf install epel-release -y
        fi
        dnf update -y && dnf install sshpass -y
    elif command -v yum >/dev/null 2>&1; then
        if ! rpm -q epel-release >/dev/null 2>&1; then
            yum install epel-release -y
        fi
        yum update -y && yum install sshpass -y
    elif command -v apt >/dev/null 2>&1; then
        apt update -y && apt install sshpass -y
    else
        exit 1
    fi
fi

if ! sshpass -p "$center_passwd" scp -o StrictHostKeyChecking=no "root@$center_host:$remote_update_source" "$local_update_path/"; then
    _red "下载失败，请检查网络连接或密码" && exit 1
else
    _green "从中心拉取Updategame.tar.gz成功！"
fi

tar zxvf "$local_update_path/updategame.tar.gz" && _green "解压成功" || { _red "解压失败"; exit 1; }

for i in $server_range; do
    dest_dir="/data/server$i/game"
    _yellow "正在处理server$i"

    [ ! -d "$dest_dir" ] && _red "目录${dest_dir}不存在，跳过server${i}更新！" && continue

    \cp -fr "$local_update_path/app/"* "$dest_dir/"

    cd "$dest_dir" || exit 1
    ./server.sh reload
    _green "server${i}更新成功！"
    separator
done