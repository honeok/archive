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
CHECK_VARS="MYSQL_HOST MYSQL_USER MYSQL_PASSWORD MYSQL_DATABASE MYSQL_TIMEZONE REDIS_HOST REDIS_DATABASE"
LAPIS_CMD="/usr/local/openresty/luajit/bin/lapis"

for var in $CHECK_VARS; do
    dev_var="DEV_$var"
    pro_var="PRO_$var"

    eval "dev_val=\${$dev_var}"
    eval "pro_val=\${$pro_var}"

    if [ -z "$dev_val" ] && [ -z "$pro_val" ]; then
        echo "ERROR: Both $dev_var and $pro_var are missing."
        exit 1
    fi
done

# 数据库迁移所需
cp -f "$WORK_DIR/src/config/migrations.lua" "$WORK_DIR/run/migrations.lua"

# 配置文件
cp -f "$WORK_DIR/src/config/models.lua" "$WORK_DIR/run/models.lua"
cp -f "$WORK_DIR/templates/mime.types" "$WORK_DIR/run/mime.types"
cp -f "$WORK_DIR/templates/nginx.conf" "$WORK_DIR/run/nginx.conf"

if ! command -v lapis >/dev/null 2>&1; then
    echo "ERROR: lapis is not installed"
    exit 1
fi

[ ! -s "$RUN_DIR/config.lua" ] && envsubst < "$WORK_DIR/templates/config.lua.template" > "$RUN_DIR/config.lua"

cd "$RUN_DIR" || { echo "ERROR: Failed to change directory!" && exit 1; }
if lapis migrate 2>/dev/null; then
    echo "Migration completed successfully!"
else
    echo "Migration failed!"
    exit 1
fi

if [ "$#" -eq 0 ]; then
    exec "$LAPIS_CMD server"
else
    exec "$@"
fi