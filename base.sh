#!/usr/bin/env bash
#
# Description: initialization script file.
#
# Copyright (C) 2000 honeok <honeok@duck.com>
#
# https://github.com/honeok/archive/raw/master/base.sh

# shellcheck disable=SC2034,SC2164

script_v='v0.0.0 (2000.01.01)' # major: 重大更新通常会导致向后不兼容的变化 minor: 小功能更新或向后兼容的改动 patch: 小修复和bug修复

yellow='\033[93m'
red='\033[31m'
green='\033[92m'
blue='\033[94m'
cyan='\033[96m'
purple='\033[95m'
gray='\033[37m'
orange='\033[38;5;214m'
white='\033[0m'
_yellow() { echo -e "${yellow}$*${white}"; }
_red() { echo -e "${red}$*${white}"; }
_green() { echo -e "${green}$*${white}"; }
_blue() { echo -e "${blue}$*${white}"; }
_cyan() { echo -e "${cyan}$*${white}"; }
_purple() { echo -e "${purple}$*${white}"; }
_gray() { echo -e "${gray}$*${white}"; }
_orange() { echo -e "${orange}$*${white}"; }
_white() { echo -e "${white}$*${white}"; }

_info_msg() { echo -e "\033[48;5;220m\033[1m提示${white} $*"; }
_err_msg() { echo -e "\033[41m\033[1m警告${white} $*"; }
_suc_msg() { echo -e "\033[42m\033[1m成功${white} $*"; }

short_separator() { printf "%-20s\n" "-" | sed 's/\s/-/g'; }
long_separator() { printf "%-40s\n" "-" | sed 's/\s/-/g'; }

export LANG=en_US.UTF-8
export DEBIAN_FRONTEND=noninteractive

if [ "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" != "/root" ]; then
    cd /root >/dev/null 2>&1
fi