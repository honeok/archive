#!/usr/bin/env bash
#
# Description: 
#
# Copyright (C) 2024 honeok <honeok@duck.com>
# Blog: www.honeok.com
# https://github.com/honeok/archive/blob/master/base.sh

# MAJOR: 重大更新通常会导致向后不兼容的变化
# MINOR: 小功能更新或向后兼容的改动
# PATCH: 小修复和bug修复
script_v="v0.0.0"

yellow='\033[93m'
red='\033[31m'
green='\033[92m'
blue='\033[94m'
cyan='\033[96m'
purple='\033[95m'
gray='\033[37m'
orange='\033[38;5;214m'
white='\033[0m'
_yellow() { echo -e ${yellow}$@${white}; }
_red() { echo -e ${red}$@${white}; }
_green() { echo -e ${green}$@${white}; }
_blue() { echo -e ${blue}$@${white}; }
_cyan() { echo -e ${cyan}$@${white}; }
_purple() { echo -e ${purple}$@${white}; }
_gray() { echo -e ${gray}$@${white}; }
_orange() { echo -e ${orange}$@${white}; }

bg_yellow='\033[48;5;220m'
bg_red='\033[41m'
bg_green='\033[42m'
bold='\033[1m'
_bg_yellow() { echo -e "${bg_yellow}${bold}$@${white}"; }
_bg_red() { echo -e "${bg_red}${bold}$@${white}"; }
_bg_green() { echo -e "${bg_green}${bold}$@${white}"; }

info_msg=$(_bg_yellow 提示)
err_msg=$(_bg_red 警告)
suc_msg=$(_bg_green 成功)
_info_msg() { echo -e "$info_msg $@"; }
_err_msg() { echo -e "$err_msg $@"; }
_suc_msg() { echo -e "$suc_msg $@"; }

# export LANG=en_US.UTF-8
export DEBIAN_FRONTEND=noninteractive

if [ "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" != "/root" ]; then
    cd /root >/dev/null 2>&1
fi