#!/usr/bin/env bash
#
# Description: This script is designed to back up production environment databases.
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# https://www.honeok.com
# https://github.com/honeok/archive/raw/master/jds/mysql_bak.sh
#      __     __       _____                  
#  __ / / ___/ /  ___ / ___/ ___ _  __ _  ___ 
# / // / / _  /  (_-</ (_ / / _ `/ /  ' \/ -_)
# \___/  \_,_/  /___/\___/  \_,_/ /_/_/_/\__/ 
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 or later.
# See <https://www.gnu.org/licenses/>

# shellcheck disable=all

set \
    -o errexit \
    -o nounset \
    -o pipefail

readonly version='v0.0.1 (2025.01.17)'

yellow='\033[1;33m'
red='\033[1;31m'
green='\033[1;32m'
white='\033[0m'
_yellow() { echo -e "${yellow}$*${white}"; }
_red() { echo -e "${red}$*${white}"; }
_green() { echo -e "${green}$*${white}"; }

_err_msg() { echo -e "\033[41m\033[1m警告${white} $*"; }
_suc_msg() { echo -e "\033[42m\033[1m成功${white} $*"; }

[ -t 1 ] && tput clear 2>/dev/null || echo -e "\033[2J\033[H" || clear
_cyan "当前脚本版本: ${version}\n"

# 操作系统和权限校验
[ "$(id -ru)" -ne "0" ] && _err_msg "$(_red '需要root用户才能运行！')" && exit 1

# https://github.com/koalaman/shellcheck/wiki/SC2155
os_name=$(grep "^ID=" /etc/*release | awk -F'=' '{print $2}' | sed 's/"//g')
timeStamp=$(date -u -d '+8 hours' +"%Y-%m-%d_%H-%M-%S")
bakDir='/data/dbbak'
readonly os_name timeStamp bakDir

# Pre run check
if [[ "$os_name" != "debian" && "$os_name" != "ubuntu" && "$os_name" != "centos" && "$os_name" != "rhel" && "$os_name" != "rocky" && "$os_name" != "almalinux" && "$os_name" != "fedora" && "$os_name" != "alinux" && "$os_name" != "opencloudos" ]]; then
    _err_msg "$(_red '当前操作系统不被支持！')"
    exit 1
fi
if [ -d "$bakDir" ]; then
    mkdir -p "$bakDir"
fi

clean_oldsql() {
    find "$bakDir" -mtime +3 -name "*.sql" | xargs rm -f
}

/usr/bin/mysqldump --no-defaults --single-transaction --set-gtid-purged=OFF -h 10.46.96.179 -P 3306 -u root -pxxxxxxxxxxx -R cbt4_game_1 > /data/dbback/cbt4_game_1_$(date +%Y%m%d%H%M%S).sql
/usr/bin/mysqldump --no-defaults --single-transaction --set-gtid-purged=OFF -h 10.46.96.179 -P 3306 -u root -pxxxxxxxxxxx -R cbt4_game_2 > /data/dbback/cbt4_game_2_$(date +%Y%m%d%H%M%S).sql
/usr/bin/mysqldump --no-defaults --single-transaction --set-gtid-purged=OFF -h 10.46.96.179 -P 3306 -u root -pxxxxxxxxxxx -R cbt4_game_3 > /data/dbback/cbt4_game_3_$(date +%Y%m%d%H%M%S).sql
/usr/bin/mysqldump --no-defaults --single-transaction --set-gtid-purged=OFF -h 10.46.96.179 -P 3306 -u root -pxxxxxxxxxxx -R cbt4_game_4 > /data/dbback/cbt4_game_4_$(date +%Y%m%d%H%M%S).sql
/usr/bin/mysqldump --no-defaults --single-transaction --set-gtid-purged=OFF -h 10.46.96.179 -P 3306 -u root -pxxxxxxxxxxx -R cbt4_game_5 > /data/dbback/cbt4_game_5_$(date +%Y%m%d%H%M%S).sql

/usr/bin/mysqldump --no-defaults --single-transaction --set-gtid-purged=OFF -h 10.46.96.179 -P 3306 -u root -pxxxxxxxxxxx -R cbt4_common > /data/dbback/cbt4_common_$(date +%Y%m%d%H%M%S).sql

/usr/bin/mysqldump --no-defaults --single-transaction --set-gtid-purged=OFF -h 10.46.96.179 -P 3306 -u root -pxxxxxxxxxxx -R cbt4_account > /data/dbback/cbt4_account_$(date +%Y%m%d%H%M%S).sql

/usr/bin/mysqldump --no-defaults --single-transaction --set-gtid-purged=OFF -h 10.46.96.179 -P 3306 -u root -pxxxxxxxxxxx -R cbt4_center > /data/dbback/cbt4_center_$(date +%Y%m%d%H%M%S).sql

#/usr/bin/mysqldump --no-defaults --single-transaction --set-gtid-purged=OFF -h 10.46.96.179 -P 3306 -u root -pxxxxxxxxxxx -R cbt4_log > /data/dbback/cbt4_log_$(date +%Y%m%d%H%M%S).sql

/usr/bin/mysqldump --no-defaults --single-transaction --set-gtid-purged=OFF -h 10.46.96.179 -P 3306 -u root -pxxxxxxxxxxx -R cbt4_report > /data/dbback/cbt4_report_$(date +%Y%m%d%H%M%S).sql

/usr/bin/mysqldump --no-defaults --single-transaction --set-gtid-purged=OFF -h 10.46.96.179 -P 3306 -u root -pxxxxxxxxxxx -R cbt4_gm > /data/dbback/cbt4_gm_$(date +%Y%m%d%H%M%S).sql