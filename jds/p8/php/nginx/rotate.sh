#!/usr/bin/env bash
#
# Description: Log rotation script for Nginx container logs to manage log size and retention.
#
# Copyright (C) 2023 - 2025 honeok <honeok@duck.com>
#
# Licensed under the GNU General Public License, version 2 only.
# This program is distributed WITHOUT ANY WARRANTY.
# See <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.

script_path=$(readlink -f "${BASH_SOURCE[0]:-$0}")
work_dir=$(dirname "$script_path")
log_dir="${work_dir}/logs"
current_time=$(TZ=Asia/Shanghai date '+%Y-%m-%d')

bark_apikey=""

# 检查日志文件是否存在
if [ ! -f "$log_dir/access.log" ] || [ ! -f "$log_dir/error.log" ]; then
    echo "error: The log files do not exist" >&2
    exit 1
fi

# 归档日志
mv "$log_dir/access.log" "$log_dir/access_$current_time.log" || { echo "error: Failed to archive access.log" >&2; exit 1; }
mv "$log_dir/error.log" "$log_dir/error_$current_time.log" || { echo "error: Failed to archive error.log" >&2; exit 1; }

# 让Nginx重新打开日志
if docker ps --format '{{.Names}}' | grep -q '^nginx$'; then
    if ! docker exec nginx nginx -s reopen >/dev/null 2>&1; then
        echo "error: Failed to reopen nginx logs" >&2
        exit 1
    fi
else
    echo "warning: Nginx container is not running" >&2
fi

# 压缩旧日志
gzip -9 "$log_dir/access_$current_time.log" "$log_dir/error_$current_time.log" || { echo "error: Failed to compress logs" >&2; exit 1; }

# 删除7天前的日志
find "$log_dir" -type f -name "*.log.gz" -mtime +7 -delete || { echo "error: Failed to delete old logs" >&2; exit 1; }

# Bark推送
if [ -n "$bark_apikey" ]; then
    if curl -Is "https://api.honeok.de/ping" >/dev/null 2>&1; then
        if ! curl -fsL -o /dev/null "https://api.honeok.de/$bark_apikey/Nginx/$(hostname)日志完成切割"; then
            echo "warning: Bark notification request failed" >&2
        fi
    else
        echo "warning: Network error, unable to reach Bark server" >&2
    fi
fi