#!/usr/bin/env bash
#
# Description: 
#
# Copyright (C) 0000 honeok <yihaohey@gmail.com>
# Blog: www.honeok.com
# Twitter: https://twitter.com/hone0k
# https://github.com/honeok/archive/blob/master/base.sh

# export LANG=en_US.UTF-8
# set -x

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

_red_bg() { echo -e "\e[41m$@${white}"; }

_error() { echo -e "\n$( _red_bg "错误" ) $@\n" && exit 1; }
_warn() { echo -e "\n$( _red_bg "警告" ) $@\n"; }
