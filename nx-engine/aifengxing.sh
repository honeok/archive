#!/usr/bin/env bash
#
# Description: This script is used for scrolling updates of h5 frontend pages.
#
# Copyright (c) 2021-2022 yihao.he <yihao.he@nx-engine.com>
#
# Thanks: zhenqiang.zhang <zhenqiang.zhang@nx-engine.com>
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

set -eu

_red() { printf "\033[91m%s\033[0m\n" "$*"; }
_green() { printf "\033[92m%s\033[0m\n" "$*"; }
_yellow() { printf "\033[93m%s\033[0m\n" "$*"; }
_err_msg() { printf "\033[41m\033[1mError\033[0m %s\n" "$*"; }

# https://www.graalvm.org/latest/reference-manual/ruby/UTF8Locale
if locale -a 2>/dev/null | grep -qiE -m 1 "UTF-8|utf8"; then
    export LANG=en_US.UTF-8
fi

# 清屏函数
clear_screen() {
    [ -t 1 ] && tput clear 2>/dev/null || echo -e "\033[2J\033[H" || clear
}

error_and_exit() {
    _err_msg "$(_red "$@")" >&2 && exit 1
}

# 系统及用户权限检查
OS_INFO=$(grep '^ID=' /etc/os-release | awk -F'=' '{print $NF}' | sed 's#"##g')
[[ "$OS_INFO" != "almalinux" && "$OS_INFO" != "centos" && "$OS_INFO" != "rhel" && "$OS_INFO" != "rocky" ]] && error_and_exit 'This Linux distribution is not supported!'
[ "$EUID" -ne 0 ] && error_and_exit 'This script must be run as root!'

# 确保工作于根目录
if [ "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" != "/root" ]; then
    cd /root >/dev/null 2>&1 || error_and_exit 'Failed to switch directory, Check permissions!'
fi

# https://www.shellcheck.net/wiki/SC1091
# shellcheck source=/dev/null
. /etc/init.d/functions

clear_screen
command -v docker >/dev/null 2>&1 || error_and_exit 'Please install the docker environment first!'
[ "$#" -ne 1 ] && error_and_exit 'No parameters provided!'
_yellow "If you encounter an error, please contact Ops (2022.01.14)."

# 容器运行环境变量
pro_variable=(
    "-e VUE_APP_BASE_URL='weixin.car.com.cn/tg-car-api/mini'"
    "-e VUE_APP_BASE_URL_OTHER='weixin.car.com.cn/tg-car-api'"
    "-e VUE_APP_BASE_URL_OTHER_API='weixin.car.com.cn/tg-car-api'"
    "-e VUE_APP_BASE_URL_DSP='gateway.car.com.cn'"
)

check_image() {
    local CONTRAST
    CONTRAST=$(docker images --format '{{.Repository}}:{{.Tag}}')

    if echo "$CONTRAST" | grep -q "$IMAGE"; then
        error_and_exit 'Mirror exists! Or please use "docker run" function!'
    fi
}

deploy_image() {
    local SVC_NAME HOST_PORT CONTAINER_PORT RUN_CONTAINER OLD_IMG
    SVC_NAME='DongFengFengXing'
    HOST_PORT='8080'
    CONTAINER_PORT='3000'
    RUN_CONTAINER=$(docker ps -q -f "name=$SVC_NAME")
    OLD_IMG=$(docker ps --format "{{.Image}}" | grep -Ei "$SVC_NAME")

    _yellow "Beginning to (update|deploy)"

    docker pull "$IMAGE" || error_and_exit 'Please check your image name and try again!'

    echo "$(date -u -d '+8 hours' +'%Y-%m-%d %H:%M:%S') changed [""$OLD_IMG""]" >> ./live_update.log

    docker stop "$RUN_CONTAINER" >/dev/null 2>&1 && action "[Stop old service container]"
    docker rm -f "$RUN_CONTAINER" >/dev/null 2>&1 && action "[Remove old service container]"

    docker run -d \
        --restart=unless-stopped \
        --name="$SVC_NAME-$RANDOM" \
        -p "$HOST_PORT":"$CONTAINER_PORT" \
        "${pro_variable[@]}" \
        "$IMAGE" \
    && action "[Deploy new service container]"

    _yellow 'Please wait 2 seconds.' && sleep 2 && docker ps | grep -i "$IMAGE"
}

prune_image() {
    (docker system prune -af --volumes >/dev/null 2>&1 && _green 'Successfully deleted unused images!') || error_and_exit 'Failed to delete unused images'
}

for IMAGE in "$@"; do
    [[ ! "$IMAGE" =~ "lq_car_uni" ]] && error_and_exit 'The provided image is not suitable for this project. Exiting!'
    check_image
    deploy_image
    prune_image
    _green "Completed"
done
exit 0