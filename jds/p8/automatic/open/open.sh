#!/usr/bin/env bash
#
# Description: automates the setup and launching of game servers.
#
# Copyright (C) 2025 zzwsec <zzwsec@163.com>
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

# shellcheck disable=all

script_dir=$(realpath "$(cd "$(dirname "${BASH_SOURCE:-$0}")" || exit; pwd)/$(basename "${BASH_SOURCE:-$0}")")
work_dir='/data/ansible/open'
listFile='/data/ansible/list.txt'

usage() {
    cat <<EOF
Usage:  $0 <server_num> [white_flag]

        参数说明:
            server_num  - 服务器编号 (必须为数字且存在于list.txt)
            white_flag  - 非空值启用白名单 (可选)
EOF
    exit 1
}

if [[ "$script_dir" != "$work_dir" ]]; then
    cd "$work_dir" || { echo "无法进入工作目录${work_dir}，请检查路径是否正确" && exit 1; }
fi

# 参数检查
if [[ $# -lt 1 || $# -gt 2 ]]; then
    usage
fi

# 验证server_num是否为数字
if ! [[ $1 =~ ^[0-9]+$ ]]; then
    echo "错误：服务器编号必须为数字"
    usage
fi

server_num=$1
white=${2:-}

# 检查list.txt是否存在
if [[ ! -f "$listFile" ]]; then
    echo "错误：list.txt文件不存在"
    exit 2
fi

# 删除list.txt的空行
sed -i '/^$/d' "$listFile"

# 获取主机名
get_host_name() {
    local line_num=$1
    if [[ ! -s "$listFile" ]]; then
        echo "错误：list.txt文件为空"
        exit 3
    fi
    if ! awk -v line="$line_num" 'NR==line {print $1; exit}' "$listFile" 2>/dev/null; then
        echo "错误：无法读取list.txt第${line_num}行"
        exit 4
    fi
}

# 通过行号获取数组
to_arr_fun() {
    local line_num=$1
    local line
    if ! line=$(sed -n "${line_num}p" "$listFile"); then
        echo "错误：读取list.txt第${line_num}行失败"
        exit 5
    fi

    # 使用正则表达式提取中括号内容
    if [[ ! $line =~ \[([^]]+)\] ]]; then
        echo "错误：list.txt第${line_num}行格式不正确"
        exit 6
    fi

    local arr=($(echo "${BASH_REMATCH[1]}" | tr ',' ' '))
    if [[ ${#arr[@]} -eq 0 ]]; then
        echo "错误：list.txt第${line_num}行未找到有效服务器编号"
        exit 7
    fi
    echo "${arr[@]}"
}

# 白名单处理
white_fun() {
    local line_num=$1
    local host_name
    if ! host_name=$(get_host_name "$line_num"); then
        exit 8
    fi

    echo "正在更新白名单（服务器：$host_name 编号：$server_num）"
    ansible-playbook -v -i "${host_name}," \
        -e "host_name=${host_name}" \
        -e "role_name=white" \
        -e "white_num=${server_num}" \
        example.yaml || {
            echo "白名单更新失败"
            exit 9
        }
}

# limit处理
limit_fun() {
    local line_num=$1
    local svc_num=$2
    local host_name
    host_name=$(get_host_name "$line_num") || exit 10

    echo "生成限制名单（主机：$host_name 终止服务：$svc_num）"

    # 清空并创建临时文件
    local limit_file="./roles/limit/files/limit_create.txt"
    : > "$limit_file"

    local arr=($(to_arr_fun "$line_num")) || exit 11

    for i in "${arr[@]}"; do
        if [[ $i -eq $svc_num ]]; then
            echo "检测到终止服务编号：$i"
            if [ $line_num -ne $row ];then
                echo $i >> "$limit_file"
            fi
            break
        fi
        echo "$i" >> "$limit_file"
    done

    echo "执行limit剧本..."
    ansible-playbook -v -i "${host_name}," \
        -e "host_name=${host_name}" \
        -e "role_name=limit" \
        example.yaml || {
            echo "limit更新失败"
            exit 12
        }
}

# 服务开启
open_fun() {
    local line_num=$1
    local svc_num=$2
    local host_name
    host_name=$(get_host_name "$line_num") || exit 13

    echo "正在开启服务（主机：$host_name 编号：$svc_num）"
    ansible-playbook -v -i "${host_name}," \
        -e "host_name=${host_name}" \
        -e "role_name=open" \
        -e "svc_num=${svc_num}" \
        example.yaml || {
            echo "服务开启失败"
            exit 14
        }
}

# 日志删除
remove_log() {
    local line_num=$1
    local svc_num=$2
    local host_name
    host_name=$(get_host_name "$line_num") || exit 15

    echo "正在删除日志（主机：$host_name 编号：$svc_num）"
    ansible -v -i "${host_name}," "${host_name}" \
        -m shell \
        -a "rm -rf /data/server${svc_num}/game/log/*" || {
            echo "日志删除失败"
            exit 16
        }
}


main() {
    # 设置时间
    local time=$(date +%FT%H:00:00)
    sed -ri 's#^(\s*open_server_time\s*=).*#\1 "'"${time}"'"#' ./roles/open/files/open_time.lua

    # 搜索匹配行
    local row=0 found=0
    while IFS= read -r line; do
        ((row++))
        if [[ $line =~ \[([^]]+)\] ]]; then
            IFS=', ' read -ra nums <<< "${BASH_REMATCH[1]}"
            for num in "${nums[@]}"; do
                if [[ $num -eq $server_num ]]; then
                    found=1
                    break 2
                fi
            done
        fi
    done < "$listFile"

    if [[ $found -eq 0 ]]; then
        echo "错误：未找到服务器编号 $server_num"
        exit 17
    fi

    echo "找到服务器配置在list.txt第${row}行"

    # 处理白名单
    [[ -n $white ]] && white_fun "$row"

    # 开启服务
    open_fun "$row" "$server_num"

    # 处理limit
    local arr=($(to_arr_fun "$row")) || exit 18
    if [[ ${arr[0]} -eq $server_num ]]; then
        if [[ $row -gt 1 ]]; then
            local prev_row=$((row-1))
	    echo "prev_row=$prev_row"
            local prev_arr=($(to_arr_fun "$prev_row")) || exit 19
	    echo "prev_arr[-1]=${prev_arr[-1]}"
            limit_fun "$prev_row" "${prev_arr[-1]}"
        else
            echo "警告：首行服务器是第一个元素，无前驱配置"
        fi
    else
        limit_fun "$row" "$server_num"
    fi

    # 清理日志
    remove_log "$row" "$server_num"

    echo "所有操作成功完成！"
}

main