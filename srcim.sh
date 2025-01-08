#!/usr/bin/env bash
#
# Description: Build Docker image via GitLab Runner pipeline task and automatically push it to a container registry.
#
# Original Author: Jimmy @Nx
# Forked and Modified by: 2021 - 2025 honeok <honeok@duck.com>
#
# https://www.honeok.com
# https://github.com/honeok/archive/raw/master/srcim.sh
#
# The name was inspired by ChatGPT.
# Special thanks to my mentor Zhenqiang for guidance and support.

# shellcheck disable=all

set \
    -o errexit

SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
SCRIPT_DIR=$(dirname $(realpath ${SCRIPT}))

TRY_PROJECT_BASE=$(
    CURRENT_DIR="${SCRIPT_DIR}" # 初始化当前目录为脚本目录
    while true; do
        # 检查当前目录是否包含版本控制目录或构建工具文件
        if [ -d "${CURRENT_DIR}/.git" ] || [ -d "${CURRENT_DIR}/.svn" ] || [ -d "${CURRENT_DIR}/.hg" ] || \
           [ -f "${CURRENT_DIR}/package.json" ] || [ -f "${CURRENT_DIR}/pom.xml" ] || [ -f "${CURRENT_DIR}/build.gradle" ]; then
            break
        fi
        # 获取当前目录的父目录
        PARENT_DIR=$(dirname "${CURRENT_DIR}")
        if [ "${CURRENT_DIR}" = "/" ] || [ "${CURRENT_DIR}" = "${PARENT_DIR}" ]; then
            echo "Error: Could not find project base directory!" >&2
            exit 1
        fi
        CURRENT_DIR="${PARENT_DIR}"
    done
    echo "${CURRENT_DIR}"
)

WORK_DIR=$(pwd)
if [[ -z ${TRY_PROJECT_BASE} ]]; then
    TRY_PROJECT_BASE=${WORK_DIR}
fi

if [[ $# -lt 1 ]]; then
    cat <<EOF
Usage:
    build for Java|Nodejs| ... Source
Example:
    $(realpath $0) /home/user/project
EOF
    exit 1
fi

printf "%-40s\n" "#" | sed 's/\s/#/g'
echo "PROJECT_BASE=${PROJECT_BASE}"
env | grep -Ev LS_COLORS
printf "%-40s\n" "#" | sed 's/\s/#/g'
echo "Start build"
GAVE_PROJECT_BASE=$(realpath $1)