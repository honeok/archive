#!/usr/bin/env bash
#
# Description: Automates the distribution of SSH keys across multiple hosts using Ansible for password-less SSH login.
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# https://github.com/honeok/archive/raw/master/jds/p8/ansible/ssh-divide.sh
#      __     __       _____                  
#  __ / / ___/ /  ___ / ___/ ___ _  __ _  ___ 
# / // / / _  /  (_-</ (_ / / _ `/ /  ' \/ -_)
# \___/  \_,_/  /___/\___/  \_,_/ /_/_/_/\__/ 
#                                             
# License Information:
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License, version 3 or later.
#
# This program is distributed WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <https://www.gnu.org/licenses/>.

set \
    -o errexit \
    -o nounset \
    -o pipefail

readonly version='v0.0.1 (2025.02.01)'

yellow='\033[93m'
red='\033[31m'
green='\033[92m'
white='\033[0m'
_yellow() { echo -e "${yellow}$*${white}"; }
_red() { echo -e "${red}$*${white}"; }
_green() { echo -e "${green}$*${white}"; }

_err_msg() { echo -e "\033[41m\033[1m警告${white} $*"; }

export DEBIAN_FRONTEND=noninteractive

[ -t 1 ] && tput clear 2>/dev/null || echo -e "\033[2J\033[H" || clear
_yellow "当前脚本版本: ${version} 💨 \n"

# 操作系统和权限校验
[ "$EUID" -ne "0" ] && _err_msg "$(_red '需要root用户才能运行！')" && exit 1

# https://github.com/koalaman/shellcheck/wiki/SC2155
os_name=$(grep "^ID=" /etc/*release | awk -F'=' '{print $2}' | sed 's/"//g')
readonly os_name

if [[ "$os_name" != "debian" && "$os_name" != "ubuntu" && "$os_name" != "centos" && "$os_name" != "rhel" && "$os_name" != "rocky" && "$os_name" != "almalinux" && "$os_name" != "fedora" && "$os_name" != "alinux" && "$os_name" != "opencloudos" ]]; then
    _err_msg "$(_red '当前操作系统不被支持！')"
    exit 1
fi

# 被控服务器
declare -a control_hosts
control_hosts=( 10.46.96.254 10.46.99.216 10.46.97.150 10.46.98.60 )

# sshkey秘钥存储路径
sshkey_path="$HOME/.ssh/id_ed25519"
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

get_passwd() {
    # 获取服务器密码 usage: echo "xxxxxxxxxxxx" > "$HOME/password.txt" && chmod 600 "$HOME/password.txt"

    if [ ! -f "$HOME/password.txt" ] || [ ! -s "$HOME/password.txt" ]; then
        _red "密码文件不存在或为空！"
        exit 1
    fi

    for pass_cmd in "head -n 1 $HOME/password.txt | tr -d '[:space:]'" "awk 'NR==1 {gsub(/^[ \t]+|[ \t]+$/, \"\"); print}' $HOME/password.txt"; do
        host_password=$(eval "$pass_cmd")

        if [ -n "$host_password" ]; then
            break
        fi
    done

    if [ -z "$host_password" ]; then
        _red "无法从文件中获取主机密码，请检查密码文件内容！"
        exit 1
    fi
}

check_sshkey() {
    if [ ! -f "$sshkey_path" ]; then
    install expect

    # https://man.openbsd.org/ssh-keygen.1#ed25519
        expect <<EOF
spawn ssh-keygen -t ed25519 -f $sshkey_path
expect {
    "Enter file in which to save the key" { send "\r"; exp_continue }
    "Enter passphrase (empty for no passphrase)" { send "\r"; exp_continue }
    "Enter same passphrase again" { send "\r"; exp_continue }
    eof
}
EOF
    fi
}

send_sshkey() {
    install sshpass

    # 并行执行 10 台主机发送 SSH 密钥，增加效率同时避免主机过多时分发密钥导致管理主机进程崩溃
    # 使用 BatchMode=yes 以非交互方式连接，ConnectTimeout=5 设置连接超时为 5 秒

    echo "${control_hosts[@]}" | xargs -n 1 -P 10 -I {} bash -c "
        if ! ssh -o BatchMode=yes -o ConnectTimeout=5 {} exit >/dev/null 2>&1; then
            sshpass -p \"$host_password\" ssh-copy-id -i \"$sshkey_path.pub\" {}
        fi
    "
}

standalone() {
    get_passwd
    check_sshkey
    send_sshkey
}

standalone