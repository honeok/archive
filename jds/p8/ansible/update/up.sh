#!/usr/bin/env bash
# vim:sw=4:ts=4:et
#
# Description: Ansible playbook launcher with automatic adaptation for various scenarios.
#
# Copyright (c) 2025 honeok <honeok@duck.com>
#
# Thanks: zzwsec <zzwsec@163.com>
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

red='\033[1;91m'
green='\033[1;92m'
yellow='\033[1;93m'
white='\033[0m'
function _red { echo -e "${red}$*${white}"; }
function _green { echo -e "${green}$*${white}"; }
function _yellow { echo -e "${yellow}$*${white}"; }

function _err_msg { echo -e "\033[41m\033[1mError${white} $*"; }
function _suc_msg { echo -e "\033[42m\033[1mSuccess${white} $*"; }

# 各变量默认值
WORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function _exists {
    local _cmd="$1"
    if type "$_cmd" >/dev/null 2>&1; then
        return 0
    elif command -v "$_cmd" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

function pkg_install {
    for package in "$@"; do
        _yellow "Installing $package"
        if _exists 'dnf'; then
            dnf install -y "$package"
        elif _exists 'yum'; then
            yum install -y "$package"
        elif _exists 'apt-get'; then
            export DEBIAN_FRONTEND=noninteractive
            apt-get install -y -q "$package"
        elif _exists 'apt'; then
            export DEBIAN_FRONTEND=noninteractive
            apt install -y -q "$package"
        elif _exists 'pacman'; then
            pacman -S --noconfirm --needed "$package"
        elif _exists 'zypper'; then
            zypper install -y "$package"
        fi
    done
}

function pre_check {
    local depend_pkg
    depend_pkg=( 'ansible' 'ansible-playbook' )

    # 检测ansible安装
    for pkg in "${depend_pkg[@]}"; do
        if ! _exists "$pkg" >/dev/null 2>&1; then
            pkg_install "$pkg"
        fi
    done
    # 如果没有共享文件夹认为是第一次使用则执行创建
    if [ ! -d "$WORK_DIR/share_files" ]; then
        mkdir -p "$WORK_DIR/share_files" >/dev/null 2>&1
        _suc_msg "$(_green "First use? $WORK_DIR/share_files created.")" && exit 0
    fi
}

function before_event {
    if [ -f "$WORK_DIR/share_files/groups.lua" ]; then
        exec_event='groups'
    elif [ -f "$WORK_DIR/share_files/increment.tar.gz" ]; then
        exec_event='increment'
    elif [ -f "$WORK_DIR/share_files/updategame.tar.gz" ]; then
        exec_event='maint'
    else
        _err_msg "$(_red 'List of tasks with no matches.')" && exit 1
    fi
}

function exec_playbook {
    case "$exec_event" in
        'groups')
            ansible-playbook cross.yml --tags 'groups'
            ansible-playbook game.yml --tags 'groups'
        ;;
        'increment')
            ansible-playbook cross.yml --tags 'increment'
            ansible-playbook game.yml --tags 'increment'
        ;;
        'maint')
            ansible-playbook cross.yml --tags 'maint'
            ansible-playbook game.yml --tags 'maint'
        ;;
        *)
            _err_msg "$(_red 'List of tasks with no matches.')" && exit 1
        ;;
    esac
}

function after_event {
    if [ -n "$WORK_DIR" ] && [ -n "$(ls -A "$WORK_DIR/share_files")" ]; then
        rm -rf "$WORK_DIR/share_files/"* 2>/dev/null
    fi
    _green 'Job Success' ; exit 0
}

function update {
    pre_check
    before_event
    exec_playbook
    after_event
}

update