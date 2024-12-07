#!/usr/bin/env bash
#
# Description: Process monitoring alarm
#
# Copyright (C) 2024 honeok <yihaohey@gmail.com>
# Blog: www.honeok.com
# https://github.com/honeok/archive/blob/master/jds/procmon.sh

# 设置警报API的URL
bark_url="x"
title="p8_Game告警"

# 获取内存占用超过30%的前10个进程
memory_alert=$(ps -eo pid,comm,%mem,%cpu --sort=-%mem | awk 'NR>1 && $3+0 > 30 {printf "进程: %s (PID: %s) 占用内存: %.1f%%\n", $2, $1, $3+0}')

# 获取CPU占用超过30%的前10个进程
cpu_alert=$(ps -eo pid,comm,%mem,%cpu --sort=-%cpu | awk 'NR>1 && $4+0 > 30 {printf "进程: %s (PID: %s) 占用CPU: %.1f%%\n", $2, $1, $4+0}')

# 合并内存和CPU警报信息
alert_message=""
if [ ! -z "$memory_alert" ]; then
    alert_message+="内存占用警报:\n$memory_alert\n"
fi

if [ ! -z "$cpu_alert" ]; then
    alert_message+="CPU占用警报:\n$cpu_alert\n"
fi

# 将换行符转换为\\n
alert_message=$(echo "$alert_message" | sed ':a;N;$!ba;s/\n/\\n/g')

# 发送警报
if [ ! -z "$alert_message" ]; then
    curl -s -X POST "$bark_url" \
        -H "Content-Type: application/json" \
        -d "{\"title\":\"$title\",\"body\":\"$alert_message\"}"
fi