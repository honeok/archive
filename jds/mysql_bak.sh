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

set \
    -o errexit \
    -o nounset \
    -o pipefail

readonly version='v0.0.2 (2025.01.20)'

yellow='\033[1;33m'
red='\033[1;31m'
green='\033[1;32m'
cyan='\033[1;36m'
white='\033[0m'
_yellow() { echo -e "${yellow}$*${white}"; }
_red() { echo -e "${red}$*${white}"; }
_green() { echo -e "${green}$*${white}"; }
_cyan() { echo -e "${cyan}$*${white}"; }

_err_msg() { echo -e "\033[41m\033[1m警告${white} $*"; }
_suc_msg() { echo -e "\033[42m\033[1m成功${white} $*"; }

separator() { printf "%-20s\n" "-" | sed 's/\s/-/g'; }

[ -t 1 ] && tput clear 2>/dev/null || echo -e "\033[2J\033[H" || clear
_cyan "当前脚本版本: ${version}\n"

# 操作系统和权限校验
[ "$(id -ru)" -ne "0" ] && _err_msg "$(_red '需要root用户才能运行！')" && exit 1

# https://github.com/koalaman/shellcheck/wiki/SC2155
os_name=$(grep "^ID=" /etc/*release | awk -F'=' '{print $2}' | sed 's/"//g')
timeStamp=$(date -u -d '+8 hours' +"%Y-%m-%d_%H:%M:%S") # 使用 UTC+8 时间戳，保证SQL文件为东八区
mysql_bak_pid='/tmp/mysql_bak.pid'
bakDir='/data/dbbak'
mysql_host='10.46.96.179'
mysql_password=$(awk 'NR==1 {gsub(/^[ \t]+|[ \t]+$/, ""); print}' "$HOME/mysql_password.txt" 2>/dev/null)
mysqldump_cmd="$(which mysqldump 2>/dev/null)"
readonly os_name mysql_bak_pid bakDir mysql_host mysql_password mysqldump_cmd

# 声明全局数组，确保跨函数使用
declare -a old_sql

if [[ "$os_name" != "debian" && "$os_name" != "ubuntu" && "$os_name" != "centos" && "$os_name" != "rhel" && "$os_name" != "rocky" && "$os_name" != "almalinux" && "$os_name" != "fedora" && "$os_name" != "alinux" && "$os_name" != "opencloudos" ]]; then
    _err_msg "$(_red '当前操作系统不被支持！')"
    exit 1
fi

trap 'rm -f "$mysql_bak_pid" >/dev/null 2>&1; exit 0' SIGINT SIGQUIT SIGTERM EXIT

if [ -f "$mysql_bak_pid" ] && kill -0 "$(cat "$mysql_bak_pid")" 2>/dev/null; then
    exit 1
fi

echo $$ > "$mysql_bak_pid"

search_oldsql() {
    old_sql=()

    if [ ! -d "$bakDir" ]; then
        mkdir -p "$bakDir" || {
            _err_msg "$(_red '创建备份目录失败')"
            exit 1
        }
    fi

    find "$bakDir" -mtime +3 -name "*.sql" | while read -r line; do
        old_sql+=("$line")
    done

    if [ "${#old_sql[@]}" -eq 0 ]; then
        _yellow "没有需要被删除的旧SQL备份"
        return
    fi

    _green "找到${#old_sql[@]}个旧的SQL文件"
    separator
}

delete_oldsql() {
    if [ "${#old_sql[@]}" -eq 0 ]; then
        _yellow "没有旧的SQL文件可删除"
        return
    fi

    for old_sql_file in "${old_sql[@]}"; do
        rm -f "$old_sql_file"
        _suc_msg "$(_green "已删除SQL文件: $old_sql_file")"
    done
}

backup_sql() {
    if [ -z "$mysql_password" ] || [ -z "$mysqldump_cmd" ]; then
        _err_msg "$(_red 'mysql密码和mysqldump命令不能为空！请检查配置和安装情况')"
        exit 1
    fi

    # 配置数据库连接参数
    local db_user="root"
    local db_password="$mysql_password"
    local db_host="$mysql_host"
    local db_port="3306"
    local mysqldump_options

    mysqldump_options="--no-defaults --single-transaction --set-gtid-purged=OFF"

    # --no-defaults: 忽略默认的配置文件，希望 mysqldump 命令不受系统默认配置文件中的设置影响，或者你担心默认配置文件中的某些设置会干扰备份过程（例如，某些连接设置或插件），可以使用该选项
    # --single-transaction: 用于在备份过程中保持数据库的一致性，mysqldump 会在开始时创建一个事务，然后在整个备份过程中保持这个事务，以确保数据的一致性。它适用于支持事务的存储引擎（如 InnoDB）
    # --set-gtid-purged=OFF: 控制 GTID（全局事务标识符）的导出。GTID 用于 MySQL 的复制功能，它确保每个事务有一个唯一的标识符，以便于复制和故障恢复

    declare -a game_db
    declare -a special_db

    # 游戏数据库
    game_db=( cbt4_game_1 cbt4_game_2 cbt4_game_3 cbt4_game_4 cbt4_game_5 cbt4_game_6 cbt4_game_7 )
    for game_db_name in "${game_db[@]}"; do
        if "$mysqldump_cmd" "$mysqldump_options" -h "$db_host" -P "$db_port" -u "$db_user" -p"$db_password" -R "$game_db_name" > "$bakDir/${game_db_name}_$timeStamp.sql"; then
            _suc_msg "$(_green "备份 ${game_db_name} 完成")"
        else
            _err_msg "$(_red "备份 ${game_db_name} 失败，暂时跳过！")"
            continue
        fi
    done

    # 其余数据库单独处理
    special_db=( cbt4_common cbt4_account cbt4_center cbt4_report cbt4_gm cbt4_gameapi )
    for special_db_name in "${special_db[@]}"; do
        if "$mysqldump_cmd" "$mysqldump_options" -h "$db_host" -P "$db_port" -u "$db_user" -p"$db_password" -R "$special_db_name" > "$bakDir/${special_db_name}_$timeStamp.sql"; then
            _suc_msg "$(_green "备份 ${special_db_name} 完成")"
        else
            _err_msg "$(_red "备份 ${special_db_name} 失败，暂时跳过！")"
            continue
        fi
    done
    separator
}

standalone() {
    search_oldsql
    backup_sql
    delete_oldsql
}

standalone