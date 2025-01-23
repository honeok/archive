#!/usr/bin/env bash

# 输入数字
target_number=$1

while read -r line; do
    # 提取IP地址和数字范围
    ip=$(echo "$line" | cut -d ' ' -f 1)
    numbers=$(echo "$line" | cut -d ' ' -f 2 | tr -d '[]')

    # 判断数字是否在范围内
    if echo "$numbers" | grep -q "\b$target_number\b"; then
        echo "Found IP: $ip"
        exit 0
    fi
done < host_mapping.txt