#!/usr/bin/env bash
#
# Description: Automates the distribution of SSH keys across multiple hosts using Ansible for password-less SSH login.
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# https://www.honeok.com
# https://github.com/honeok/archive/raw/master/jds/ansible/ssh-divide.sh
#      __     __       _____                  
#  __ / / ___/ /  ___ / ___/ ___ _  __ _  ___ 
# / // / / _  /  (_-</ (_ / / _ `/ /  ' \/ -_)
# \___/  \_,_/  /___/\___/  \_,_/ /_/_/_/\__/ 
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 or later.
# See <https://www.gnu.org/licenses/>

set \
    -o errexit \
    -o nounset

yellow='\033[93m'
red='\033[31m'
green='\033[92m'
_yellow() { echo -e "${yellow}$*${white}"; }
_red() { echo -e "${red}$*${white}"; }
_green() { echo -e "${green}$*${white}"; }

# 被控服务器组
control_hosts=( 192.168.100.10 192.168.100.20 )
# sshkey秘钥存储路径
readonly key_path="$HOME/.ssh/id_rsa"

install() {
    if [ $# -eq 0 ]; then
        _red "未提供软件包参数"
        return 1
    fi

    for package in "$@"; do
        if ! command -v "$package" >/dev/null 2>&1; then
            _yellow "正在安装$package"
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y epel-release
                dnf install -y "$package"
            elif command -v yum >/dev/null 2>&1; then
                yum install -y epel-release
                yum install -y "$package"
            elif command -v apt >/dev/null 2>&1; then
                apt install -y "$package"
            else
                _red "未知的包管理器！"
                return 1
            fi
        else
            _green "${package}已经安装！"
        fi
    done
    return 0
}

get_password() {
    # 获取服务器密码 usage: echo "xxxxxxxxxxxx" > "$HOME/password.txt" && chmod 600 "$HOME/password.txt"
    if [ -f "$HOME/password.txt" ] && [ -s "$HOME/password.txt" ]; then
        host_password=$(head -n 1 "$HOME/password.txt" | tr -d '[:space:]')
    fi
    if [ -z "$host_password" ]; then
        host_password=$(awk 'NR==1 {gsub(/^[ \t]+|[ \t]+$/, ""); print}' "$HOME/password.txt")
    fi
    if [ -z "$host_password" ]; then
        _red "无法获取主机密码！"
        exit 1
    fi
}

check_cmd() {
    install expect sshpass
}

check_sshkey() {
    if [ ! -f "$key_path" ]; then
    expect <<EOF
spawn ssh-keygen -t rsa -b 4096 -f $key_path
expect "Enter file in which to save the key" { send "\r" }
expect "Enter passphrase (empty for no passphrase)" { send "\r" }
expect "Enter same passphrase again" { send "\r" }
expect eof
EOF
    fi
}

send_sshkey() {
    # 并行执行 10 台主机发送 SSH 密钥，增加效率
    # 同时避免主机过多时分发密钥导致管理主机崩溃进程

    # 使用 BatchMode=yes 以非交互方式连接，ConnectTimeout=5 设置连接超时为 5 秒
    echo "${control_hosts[@]}" | xargs -n 1 -P 10 -I {} bash -c "
        if ! ssh -o BatchMode=yes -o ConnectTimeout=5 {} exit >/dev/null 2>&1; then
            sshpass -p \"$host_password\" ssh-copy-id -i \"$key_path.pub\" {}
        fi
    "
}

standalone() {
    get_password
    check_cmd
    check_sshkey
    send_sshkey
}

standalone