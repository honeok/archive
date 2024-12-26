#!/usr/bin/env bash
#
# Description: Automatically determines the server path and reloads configurations.
#
# Copyright (C) 2024 honeok <honeok@duck.com>

version='v0.0.2 (2024.12.26)'

yellow='\033[93m'
red='\033[31m'
green='\033[92m'
white='\033[0m'
_yellow() { echo -e ${yellow}$@${white}; }
_red() { echo -e ${red}$@${white}; }
_green() { echo -e ${green}$@${white}; }
separator() { printf "%-20s\n" "-" | sed 's/\s/-/g'; }

export DEBIAN_FRONTEND=noninteractive

server_range=$(find /data/ -maxdepth 1 -type d -name "server*" | sed 's:.*/::' | grep -E '^server[0-9]+$' | sed 's/server//' | sort -n)
local_update_dir='/data/update'
remote_update_file='/data/update/updategame.tar.gz'
update_host='10.46.96.254'

# 操作系统和权限校验
os_name=$(grep ^ID= /etc/*release | awk -F'=' '{print $2}' | sed 's/"//g')
[[ "$os_info" != "debian" && "$os_info" != "ubuntu" && "$os_info" != "centos" && "$os_info" != "rhel" && "$os_info" != "rocky" && "$os_info" != "almalinux" ]] && exit 0
[ "$(id -u)" -ne "0" ] && exit 1

# 检查Server目录
[ -z "$server_range" ] && _red "未找到任何有效的server目录！" && exit 1
# 获取服务器密码 usage: echo "xxxxxxxxxxxx" > ~/password.txt && chmod 600 ~/password.txt
[ -f /root/password.txt ] && [ -s /root/password.txt ] || exit 1
update_host_passwd=$(head -n 1 /root/password.txt | tr -d '[:space:]' | xargs)
[ -n "$update_host_passwd" ] || exit 1

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

_yellow "当前脚本版本: "${version}""

cd $local_update_dir
rm -rf *

if ! sshpass -p "$update_host_passwd" scp -o StrictHostKeyChecking=no "root@$update_host:$remote_update_file" "$local_update_dir/"; then
    _red "下载失败，请检查网络连接或密码" && exit 1
else
    _green "从中心拉取Updategame.tar.gz成功！"
fi

tar zxvf "$local_update_dir/updategame.tar.gz" && _green "解压成功" || { _red "解压失败"; exit 1; }

for server_num in $server_range; do
    dest_dir="/data/server$server_num/game"
    _yellow "正在处理server$server_num"

    if [ ! -d "$dest_dir" ]; then
        _red "目录${dest_dir}不存在，跳过server${server_num}更新！"
        continue
    fi

    \cp -rf "$local_update_dir/app/"* "$dest_dir/"
    cd "$dest_dir" || exit 1
    ./server.sh reload
    _green "server${server_num}更新成功！"
    separator
done