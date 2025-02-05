#!/bin/bash
#
# Description: managing file permissions of HTML files in a production PHP environment.
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
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

red='\033[1;31m'
green='\033[92m'
white='\033[0m'
_red() { echo -e "${red}$*${white}"; }
_green() { echo -e "${green}$*${white}"; }

_suc_msg() { echo -e "\033[42m\033[1m成功${white} $*"; }
_err_msg() { echo -e "\033[41m\033[1mwarn${white} $*"; }
_info_msg() { echo -e "\033[43m\033[1;37minfo${white} $*"; }

nginx_name="nginx"
php_name="php"

if [ "$(id -ru)" -ne "0" ]; then
    _err_msg "$(_red 'The script requires root permission!')" && exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
    _err_msg "$(_red 'Docker is not installed on the system!')"
    exit 1
fi

if docker compose version >/dev/null 2>&1; then
    compose_cmd="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    compose_cmd="docker-compose"
else
    compose_cmd=""
fi

_info_msg 'Ensure the container restart is in maintenance mode. Press any key to confirm!'
read -n 1 -s -r -p ""

if docker ps -q -f name="$nginx_name"; then
    docker exec "$nginx_name" chown -R nginx:nginx /var/www/html
else
    _err_msg "$(_red "$nginx_name container failed to modify file permissions!")" && exit 1
fi
if docker ps -q -f name="$php_name"; then
    docker exec "$php_name" chown -R www-data:www-data /var/www/html
else
    _err_msg "$(_red "$php_name container failed to modify file permissions!")" && exit 1
fi

if [ -n "$compose_cmd" ]; then
    "$compose_cmd" restart 1>/dev/null
    _suc_msg "$(_green 'PHP environment container reboot completed!')" && exit 0
else
    _err_msg "$(_red 'Docker compose command not found!')" && exit 1
fi