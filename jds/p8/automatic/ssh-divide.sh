#!/usr/bin/env bash
#
# Description: distributes ssh keys across multiple hosts.
#
# Copyright (C) 2025 zzwsec <zzwsec@163.com>
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

set \
    -o errexit \
    -o nounset \
    -o pipefail \
    -o noclobber

readonly version='v0.0.3 (2025.02.15)'

yellow='\033[1;33m'
red='\033[1;31m'
green='\033[1;32m'
white='\033[0m'
_yellow() { echo -e "${yellow}$*${white}"; }
_red() { echo -e "${red}$*${white}"; }
_green() { echo -e "${green}$*${white}"; }

_err_msg() { echo -e "\033[41m\033[1m警告${white} $*"; }
_suc_msg() { echo -e "\033[42m\033[1m成功${white} $*"; }

export DEBIAN_FRONTEND=noninteractive

[ -t 1 ] && tput clear 2>/dev/null || echo -e "\033[2J\033[H" || clear
_yellow "当前脚本版本: ${version} 🍴 \n"

# 操作系统和权限校验
if [ "$(id -ru)" -ne "0" ]; then
    _err_msg "$(_red '需要root用户才能运行！')" && exit 1
fi

# https://github.com/koalaman/shellcheck/wiki/SC2155
os_name=$(grep "^ID=" /etc/*release | awk -F'=' '{print $2}' | sed 's/"//g')
readonly os_name

if [[ "$os_name" != "debian" && "$os_name" != "ubuntu" && "$os_name" != "centos" && "$os_name" != "rhel" && "$os_name" != "rocky" && "$os_name" != "almalinux" && "$os_name" != "fedora" && "$os_name" != "alinux" && "$os_name" != "opencloudos" ]]; then
    _err_msg "$(_red '当前操作系统不被支持！')"
    exit 1
fi

# 被控服务器
declare -a control_hosts
control_hosts=( 192.168.250.250 192.168.250.251 192.168.250.252 192.168.250.253 192.168.250.254 )

# sshkey秘钥存储路径
sshkey_path="$HOME/.ssh/id_rsa"
readonly sshkey_path

install() {
    if [ "$#" -eq 0 ]; then
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
            elif command -v apt-get >/dev/null 2>&1; then
                apt-get install -y "$package"
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

obtain_passwd() {
    # 获取服务器密码 usage: echo "xxxxxxxxxxxx" > "$HOME/password.txt" && chmod 600 "$HOME/password.txt"
    if [ ! -s "$HOME/password.txt" ]; then
        _red "密码文件不存在或为空！" && exit 1
    fi

    for _cmd in "head -n 1 $HOME/password.txt | tr -d '[:space:]'" "awk 'NR==1 {gsub(/^[ \t]+|[ \t]+$/, \"\"); print}' $HOME/password.txt"; do
        host_password=$(eval "$_cmd")
        if [ -n "$host_password" ]; then
            break
        fi
    done

    if [ -z "$host_password" ]; then
        _red "无法从文件中获取主机密码，请检查密码文件内容！" && exit 1
    fi
}

check_sshkey() {
    if [ ! -f "$sshkey_path" ]; then
        if ! ssh-keygen -t rsa -f "$sshkey_path" -P '' >/dev/null 2>&1; then
            _err_msg "$(_red '密钥创建失败，请重试！')" && exit 1
        fi
    fi
}

send_sshkey() {
    install sshpass

    # 并行执行提高效率
    for host in "${control_hosts[@]}"; do
        # 启动子进程，每个分发操作完全独立运行在新的进程中
        # 子进程报错退出避免主机过多导致进程崩溃
        (
            _yellow "正在向 $host 分发公钥"
            if ! sshpass -p"${host_password}" ssh-copy-id -i "$sshkey_path" -o StrictHostKeyChecking=no -o ConnectTimeout=30 root@"${host}" >/dev/null 2>&1; then
                _err_msg "$(_red "$host 公钥分发失败！")" && exit 1
            fi
            _suc_msg "$(_green "$host 公钥分发成功")"
        ) &
    done

    wait # 等待并行任务
}

standalone() {
    obtain_passwd
    check_sshkey
    send_sshkey
}

standalone