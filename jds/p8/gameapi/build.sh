#!/usr/bin/env sh
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

set \
    -o errexit \
    -o nounset

WORK_DIR="/gameapi"
RUN_DIR="$WORK_DIR/run"
LUAJIT_BIN="/usr/local/openresty/luajit/bin/luajit"
HAS_ERROR=0

[ -d "${RUN_DIR:?}" ] && find "$RUN_DIR" -mindepth 1 -delete

# lua语法检查
if [ ! -f "$LUAJIT_BIN" ]; then
    echo "ERROR: LuaJIT not found at: $LUAJIT_BIN."
    exit 1
fi
find "$WORK_DIR" -name "*.lua" ! -path "$WORK_DIR/run/*" -print0 | xargs -0 -I {} sh -c '
    if ! "'"$LUAJIT_BIN"'" -b "{}" /dev/null 2>/dev/null; then
        echo "ERROR: Syntax error in: {}"
        "'"$LUAJIT_BIN"'" -b "{}" /dev/null 2>&1 | sed "s/^/  /"
        exit 1
    fi
' || HAS_ERROR=1
[ "$HAS_ERROR" -eq 1 ] && exit 1

# 运行环境准备
mkdir -p \
    "$RUN_DIR/logs" \
    "$RUN_DIR/temp/client-body" \
    "$RUN_DIR/temp/proxy" \
    "$RUN_DIR/temp/fastcgi" \
    "$RUN_DIR/temp/uwsgi" \
    "$RUN_DIR/temp/scgi"

# 数据库迁移所需
cp -f "$WORK_DIR/src/config/migrations.lua" "$WORK_DIR/run/migrations.lua"

# 配置文件
cp -f "$WORK_DIR/src/config/models.lua" "$WORK_DIR/run/models.lua"
cp -f "$WORK_DIR/templates/mime.types" "$WORK_DIR/run/mime.types"
cp -f "$WORK_DIR/templates/nginx.conf" "$WORK_DIR/run/nginx.conf"