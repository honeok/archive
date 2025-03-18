#!/usr/bin/env sh
#
# Description: Automatically generates game-related configurations with ease.
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

set \
    -o errexit \
    -o nounset

IS_SCRIPT="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="$(dirname "$IS_SCRIPT")"

if ! command -v envsubst >/dev/null 2>&1; then
    echo 'Error: envsubst command not found.' && exit 1
fi

# --> Server.app.lua
# 域
 : "${DOMAIN?error: DOMAIN missing}"
 # 本地地址
 : "${LOCAL_ADDRESS?error: LOCAL_ADDRESS missing}"
 # 服务发现
 : "${DISCOVER_NODE1?error: DISCOVER_NODE1 missing}"
 : "${DISCOVER_NODE2?error: DISCOVER_NODE2 missing}"
 : "${DISCOVER_NODE3?error: DISCOVER_NODE3 missing}"
 # 数据库对接
 : "${GAMEDB_HOST?error: GAMEDB_HOST missing}"
 : "${GAMEDB_USER?error: GAMEDB_USER missing}"
 : "${GAMEDB_PASSWORD?error: GAMEDB_PASSWORD missing}"
 : "${GAMEDB_DATABASE?error: GAMEDB_DATABASE missing}"
 # 组编号
 : "${GROUP_ID?error: GROUP_ID missing}"
 # 区域编号
 : "${AREA_ID?error: AREA_ID missing}"
 # kingnet回调地址
 : "${PAY_NOTIFY?error: PAY_NOTIFY missing}"

 # --> Server.log.ini
 : "${LOG_LEVEL?error: LOG_LEVEL missing}"

 # --> Zones.lua
 # 小区列表
 : "${ZONES_NUM?error: ZONES_NUM missing}"
 : "${ZONE_VALUE?error: ZONE_VALUE missing}"

 # --> Open_time.lua
 # 开服时间
 : "${OPEN_SERVER_TIME?error: OPEN_SERVER_TIME missing}"

# Generate config
envsubst < "$WORK_DIR/templates/game/server.app.template.lua" > "$WORK_DIR/etc/server.app.lua"
envsubst < "$WORK_DIR/templates/game/server.log.template.ini" > "$WORK_DIR/etc/server.log.ini"
envsubst < "$WORK_DIR/templates/game/zones.template.lua" > "$WORK_DIR/etc/zones.lua"
envsubst < "$WORK_DIR/templates/game/open_time.template.lua" > "$WORK_DIR/lua/config/open_time.lua"