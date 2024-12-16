#!/usr/bin/env bash
#
# Description: Server Rereading.
#
# Copyright (C) 2024 honeok <honeok@duck.com>
# Blog: www.honeok.com
# https://github.com/honeok/archive/blob/master/jds/game-reload.sh

version='v0.0.2 (2024.12.16)'

yellow='\033[93m'
red='\033[31m'
green='\033[92m'
white='\033[0m'
_yellow() { echo -e ${yellow}$@${white}; }
_red() { echo -e ${red}$@${white}; }
_green() { echo -e ${green}$@${white}; }
separator() { printf "%-20s\n" "-" | sed 's/\s/-/g'; }

server_range=$(find /data/ -maxdepth 1 -type d -name "server*" | sed 's:.*/::' | grep -E '^server[0-9]+$' | sed 's/server//' | sort -n)
local_update_path="/data/update"
remote_update_source="/data/update/updategame.tar.gz"
center_host="10.46.96.254"

# 验证操作系统和权限
os_name=$(grep ^ID= /etc/*release | awk -F'=' '{print $2}' | sed 's/"//g')
[[ "$os_name" != "debian" && "$os_name" != "ubuntu" && "$os_name" != "centos" && "$os_name" != "rocky" && "$os_name" != "alma" ]] && exit 0
[ "$(id -u)" -ne "0" ] && exit 1

# 检查Center密码文件
# echo "xxxxxxxxxxxx" > /root/password.txt chmod 600 /root/password.txt 只有root用户可以读取该文件
[ -f /root/password.txt ] && [ -s /root/password.txt ] || exit 1
center_passwd=$(cat /root/password.txt)
[ -n "$center_passwd" ] || exit 1
# 检查Server目录
[ -z "$server_range" ] && _red "未找到任何有效的server目录！" && exit 1

cd $local_update_path || exit 1
rm -fr *

if ! command -v sshpass >/dev/null 2>&1; then
    if command -v dnf >/dev/null 2>&1; then
        [[ ! $(rpm -q epel-release) ]] && dnf install epel-release -y
        dnf update -y && dnf install sshpass -y
    elif command -v yum >/dev/null 2>&1; then
        [[ ! $(rpm -q epel-release) ]] && yum install epel-release -y
        yum update -y && yum install sshpass -y
    elif command -v apt >/dev/null 2>&1; then
        apt update -y && apt install sshpass -y
    else
        exit 1
    fi
fi

_yellow "当前脚本版本 "${version}""
if ! sshpass -p "$center_passwd" scp -o StrictHostKeyChecking=no "root@$center_host:$remote_update_source" "$local_update_path/"; then
    _red "下载失败，请检查网络连接或密码" && exit 1
else
    _green "从中心拉取Updategame.tar.gz成功！"
fi

tar zxvf "$local_update_path/updategame.tar.gz" && _green "解压成功" || { _red "解压失败"; exit 1; }

for i in $server_range; do
    dest_dir="/data/server$i/game"
    _yellow "正在处理server$i"

    if [ ! -d "$dest_dir" ]; then
        _red "目录${dest_dir}不存在，跳过server${i}更新！"
        continue
    fi

    \cp -fr "$local_update_path/app/"* "$dest_dir/"

    cd "$dest_dir" || exit 1
    ./server.sh reload
    _green "server${i}更新成功！"
    separator
done