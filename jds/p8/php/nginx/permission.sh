#!/usr/bin/env bash
#
# Description: managing file permissions of HTML files in a production PHP environment.
#
# Copyright (C) 2025 honeok <honeok@duck.com>
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

yellow='\033[93m'
red='\033[1;31m'
green='\033[92m'
white='\033[0m'
_yellow() { echo -e "${yellow}$*${white}"; }
_red() { echo -e "${red}$*${white}"; }
_green() { echo -e "${green}$*${white}"; }

_suc_msg() { echo -e "\033[42m\033[1m成功${white} $*"; }
_err_msg() { echo -e "\033[41m\033[1m警告${white} $*"; }
_info_msg() { echo -e "\033[43m\033[1;37m提示${white} $*"; }

nginx_name='nginx'
php_name='php'
readonly nginx_name php_name

if [ "$(id -ru)" -ne "0" ]; then
    _err_msg "$(_red '需要root用户才能运行!')" && exit 1
fi

compose_cmd() {
    local _cmd _compose_v

    if docker compose version >/dev/null 2>&1; then
        _cmd="docker compose"
        _compose_v="docker compose version"
    elif command -v docker-compose >/dev/null 2>&1; then
        _cmd="docker-compose"
        _compose_v="docker-compose --version"
    else
        _err_msg "$(_red '系统上未安装Docker Compose!')" && exit 1
    fi

    case "$1" in
        start)
            $_cmd up -d
        ;;
        stop)
            $_cmd down
        ;;
        restart)
            $_cmd restart
        ;;
        version)
            eval "$_compose_v"
        ;;
    esac
}

main() {
    if docker ps -q -f name="$nginx_name"; then
        docker exec "$nginx_name" chown -R nginx:nginx /var/www/html 2>/dev/null
    else
        _err_msg "$(_red "$nginx_name 无法修改容器内文件权限")" && exit 1
    fi
    if docker ps -q -f name="$php_name"; then
        docker exec "$php_name" chown -R www-data:www-data /var/www/html 2>/dev/null
    else
        _err_msg "$(_red "$php_name 无法修改容器内文件权限")" && exit 1
    fi
    if compose_cmd restart 1>/dev/null; then
        _suc_msg "$(_green 'PHP环境容器重启完成!')" && exit 0
    else
        _err_msg "$(_red 'PHP环境容器重启失败!')" && exit 1
    fi
}

if ! command -v docker >/dev/null 2>&1; then
    _err_msg "$(_red '系统上未安装Docker!')"
    exit 1
elif ! compose_cmd version >/dev/null 2>&1; then
    _err_msg "$(_red '系统上未安装Docker Compose!')"
    exit 1
fi

_info_msg "$(_yellow '确保容器重启处于维护时间段, 按任意键确认!')"
read -n 1 -s -r -p ""

main