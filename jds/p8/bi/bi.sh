#!/usr/bin/env bash
#
# Description: sets up the BI environment by installing Miniconda3 and other dependencies.
#
# Copyright (C) 2024 - 2025 honeok <honeok@duck.com>
#
# https://www.honeok.com
# https://github.com/honeok/archive/raw/master/jds/bi.sh
#      __     __       _____                  
#  __ / / ___/ /  ___ / ___/ ___ _  __ _  ___ 
# / // / / _  /  (_-</ (_ / / _ `/ /  ' \/ -_)
# \___/  \_,_/  /___/\___/  \_,_/ /_/_/_/\__/ 
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 or later.
# See <https://www.gnu.org/licenses/>

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

conda_dir="/data/conda3"
# conda_script="Miniconda3-py39_24.3.0-0-Linux-x86_64.sh"
conda_script="Miniconda3-py39_24.3.0-0-$(uname -s)-$(uname -m).sh"
apiserver_dir="/data/bi/apiserver"

geo_check() {
    local cloudflare_api ipinfo_api ipsb_api

    cloudflare_api=$(curl -A "Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/81.0" -m 10 -s "https://dash.cloudflare.com/cdn-cgi/trace" | sed -n 's/.*loc=\([^ ]*\).*/\1/p')
    ipinfo_api=$(curl -fsL --connect-timeout 5 https://ipinfo.io/country)
    ipsb_api=$(curl -fsL --connect-timeout 5 -A Mozilla https://api.ip.sb/geoip | sed -n 's/.*"country_code":"\([^"]*\)".*/\1/p')

    for api in "$cloudflare_api" "$ipinfo_api" "$ipsb_api"; do
        if [ -n "$api" ]; then
            country="$api"
            break
        fi
    done

    if [ -z "$country" ]; then
        _err_msg "$(_red '无法获取服务器所在地区，请检查网络后重试！')"
        exit 1
    fi
}

install_conda() {
    local repo_url pypi_url

    geo_check

    if command -v conda >/dev/null 2>&1; then
        _err_msg "$(_red 'Conda已经安装在系统中，跳过安装步骤')"
        exit 1
    fi

    if [[ "$country" == "CN" ]]; then
        repo_url="https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/$conda_script"
        pypi_url="https://pypi.tuna.tsinghua.edu.cn/simple"
    else
        repo_url="https://repo.anaconda.com/miniconda/$conda_script"
        pypi_url="https://pypi.org/simple"
    fi

    # 下载和安装Miniconda
    if [ ! -f "$conda_script" ]; then
        _yellow "下载Miniconda安装脚本"
        curl -L -O "$repo_url" || { _err_msg "$(_red '下载Miniconda安装脚本失败')"; exit 1; }
    fi

    _yellow "安装Miniconda到${conda_dir}"
    bash -bfp "$conda_script" "$conda_dir" || { _err_msg "$(_red 'Miniconda安装失败')"; exit 1; }

    [ -f "$conda_script" ] && rm -f "$conda_script"

    # 配置全局环境变量
    if ! grep -q "$conda_dir/bin" "$HOME/.bashrc"; then
        _yellow "正在配置全局环境变量"
        echo "export PATH=\"$conda_dir/bin:\$PATH\"" >> "$HOME/.bashrc"
    fi

    # https://www.shellcheck.net/wiki/SC1091
    # shellcheck source=/dev/null
    source "$HOME/.bashrc"

    # 验证Miniconda安装
    if ! conda --version >/dev/null 2>&1; then
        _err_msg "$(_red 'Conda安装错误')"
        # 删除安装目录和环境变量文件
        [ -d "$conda_dir" ] && rm -rf "$conda_dir" >/dev/null 2>&1
        remove_condaenv
        # shellcheck source=/dev/null
        source "$HOME/.bashrc"
        exit 1
    fi

    _yellow "更新Conda并安装Python3.9"
    conda install -y python=3.9 || { _err_msg "$(_red 'Conda安装Python3.9失败')"; exit 1; }
    conda update -y conda || { _err_msg "$(_red '更新Conda失败')"; exit 1; }
    conda clean --all --yes || { _err_msg "$(_red '清理Conda缓存失败')"; exit 1; }

    _yellow "创建Python39虚拟环境"
    conda create -n py39 python=3.9 --yes || { _err_msg "$(_red '创建Python39环境失败')"; exit 1; }
    # shellcheck source=/dev/null
    source "${conda_dir}/etc/profile.d/conda.sh" || { _err_msg "$(_red '加载Conda配置失败')"; exit 1; }
    conda init || { _err_msg "$(_red '初始化Conda失败')"; exit 1; }
    conda activate py39 || { _err_msg "$(_red '激活py39环境失败')"; exit 1; }

    if [ ! -d "$apiserver_dir" ]; then
        _err_msg "$(_red "${apiserver_dir}目录不存在请检查路径")"
        # 删除安装目录和环境变量文件
        [ -d "$conda_dir" ] && rm -rf "$conda_dir"
        remove_condaenv
        # shellcheck source=/dev/null
        source "$HOME/.bashrc"
        exit 1
    fi

    _yellow "安装所需的Python包"
    cd "$apiserver_dir" || exit 1
    python -m pip install -i "$pypi_url" --trusted-host "$(echo "$pypi_url" | awk -F/ '{print $3}')" -r requirements.txt || { _red "从requirements.txt安装包失败"; exit 1; }

    [ -d "migrations/models" ] && rm -rf migrations/models

    _yellow "初始化数据库"
    python manager.py initdb || { _err_msg "$(_red '初始化数据库失败')"; exit 1; }

    aerich init -t aerich_env.TORTOISE_ORM
    aerich init-db

    _suc_msg "$(_green "安装成功")"
}

remove_condaenv() {
    grep -q '# >>> conda initialize >>>' ~/.bashrc && \
        sed -i '/# >>> conda initialize >>>/,/# <<< conda initialize <<<$/d' ~/.bashrc && \
        _suc_msg "$(_green '已删除.bashrc中的Conda初始化配置块')"

    grep -q '# commented out by conda initialize' ~/.bashrc && \
        sed -i '/# commented out by conda initialize/d' ~/.bashrc && \
        _suc_msg "$(_green '已删除.bashrc中的Conda路径配置')"
}

uninstall_conda() {
    _yellow "卸载Miniconda和相关配置"

    # 删除Miniconda安装目录
    if [ -d "$conda_dir" ]; then
        _yellow "删除Miniconda安装目录$conda_dir"
        rm -rf "$conda_dir" || { _err_msg "$(_red '删除Miniconda目录失败')"; exit 1; }
    else
        _err_msg "$(_red "${conda_dir}不存在，跳过删除")"
    fi

    # 删除环境变量
    remove_condaenv

    # 检查并删除虚拟环境
    if conda info --envs | grep -q 'py39'; then
        _yellow "删除Conda虚拟环境py39"
        if ! conda remove -n py39 --all --yes; then
            _err_msg "$(_red '删除py3.9虚拟环境失败')"
            exit 1
        fi
    else
        _err_msg "$(_red '未找到py39虚拟环境，本次跳过')"
    fi

    _suc_msg "$(_green '卸载成功')"
}

clear

if [ "$#" -eq 0 ]; then
    install_conda
    exit 0
else
    while [[ "$#" -ge 1 ]]; do
        case "$1" in
            -d | -D)
                shift
                uninstall_conda
                exit 0
                ;;
            *)
                _err_msg "$(_red "无效选项, 当前参数 $1 不被支持！")"
                exit 1
                ;;
        esac
    done
fi