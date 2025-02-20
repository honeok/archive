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

return 0