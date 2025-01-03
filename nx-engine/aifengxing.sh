#!/usr/bin/env bash
#
# Description: h5 container rolling update.
# System Required:  centos7+ rhel8+ rocky8+ alma8+
#
# Copyright (C) 2021 - 2022 nx-engine <yihao.he@nx-engine.com>
# https://www.nx-engine.com
# https://github.com/honeok/archive/raw/master/nx-engine/aifengxing.sh
#
# Archived after Updates On: 2024.12.25

set -e
clear

host_port='8080'
container_port='3000'
svc_name='DongFengFengXing'

yellow='\033[93m'
red='\033[31m'
green='\033[92m'
white='\033[0m'
_yellow() { echo -e "${yellow}$*${white}"; }
_red() { echo -e "${red}$*${white}"; }
_green() { echo -e "${green}$*${white}"; }
_err_msg() { echo -e "\033[41m\033[1m警告${white} $*"; }

# Check OS type
os_info=$(grep ^ID= /etc/*release | awk -F'=' '{print $2}' | sed 's/"//g')
[[ "$os_info" != "centos" && "$os_info" != "rhel" && "$os_info" != "rocky" && "$os_info" != "almalinux" ]] && exit 0
[ "$(id -u)" -ne "0" ] && _err_msg "$(_red '需要root用户才能运行！')" && exit 1

# Ensure running from root directory
if [ "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" != "/root" ]; then
    cd /root >/dev/null 2>&1
fi

. /etc/init.d/functions

# Validate parameters
if [ $# -lt 1 ]; then
    _red "No parameters provided！" && exit 1
fi

_yellow "Update on 2022.01.14 if there is an error！ @OP"

pro_variable=(
    "-e VUE_APP_BASE_URL='weixin.car.com.cn/tg-car-api/mini'"
    "-e VUE_APP_BASE_URL_OTHER='weixin.car.com.cn/tg-car-api'"
    "-e VUE_APP_BASE_URL_OTHER_API='weixin.car.com.cn/tg-car-api'"
    "-e VUE_APP_BASE_URL_DSP='gateway.car.com.cn'"
)

check_image() {
    local contrast
    contrast=$(docker images --format '{{.Repository}}:{{.Tag}}')

    if echo "${contrast}" | grep -q "$param"; then
        _red "Mirror exists！Or Please use \"docker run\" function！" && exit 1
    fi
}

deploy_image() {
    local runcon old_img_log
    runcon=$(docker ps -q -f "name=${svc_name}")
    old_img_log=$(docker ps --format "{{.Image}}" | grep -Ei "${svc_name}")

    _yellow "Beginning to (update|deploy)"

    docker pull "${param}" || { _red "Please check your image name and try again！"; exit 1; } 

    echo "$(date -u -d '+8 hours' +'%Y-%m-%d %H:%M:%S') changed [${old_img_log}]" >> ./live_oldimage.log

    # Stop and remove the old container
    echo "" && docker stop "${runcon}" >/dev/null 2>&1 && action "[Stop old service container]"
    echo "" && docker rm -f "${runcon}" >/dev/null 2>&1 && action "[Remove old service container]"

    # Run the new container
    echo "" && docker run -d --restart=unless-stopped --name="${svc_name}-$RANDOM" -p "${host_port}:${container_port}" "${pro_variable[@]}" "${param}" && action "[Deploy new service container]"

    # Wait for the container to be fully started
    _yellow "Please wait 2 seconds" && sleep 2 && docker ps | grep -i "${param}"
}

prune_image() {
    if docker image prune -a -f >/dev/null 2>&1; then
        _green "successfully deleted unused images"
    else
        _red "failed to delete unused images"
    fi
}

for param in "$@"; do
    if [[ ! ${param} =~ "lq_car_uni" ]]; then
        _red "The provided image is not suitable for this project. Exiting！" && exit 1
    fi

    check_image
    deploy_image
    prune_image

    _green "Completed"
done
