#!/usr/bin/env sh
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

set \
    -o errexit \
    -o nounset

WORK_DIR="/gmapi"
RUN_DIR="$WORK_DIR/run"

DEPEND_VARS="
    KINGNET_APP_KEY KINGNET_GM_URL
    MYSQL_HOST MYSQL_USER MYSQL_PASSWORD MYSQL_DATABASE
    CACHE_DATABASE
    GAME_GM_URL
    OBS_ACCESS_KEY_ID OBS_ACCESS_KEY OBS_ENDPOINT OBS_BUCKET OBS_SERVERLIST_NAME OBS_NOTICE_NAME
    CDN_REFRESH_URL CDN_URL CDN_PROJECT_ID CDN_ACCESS_KEY_ID CDN_ACCESS_KEY
"

for VAR in $DEPEND_VARS; do
    if [ -z "$(eval echo \$"$VAR")" ]; then
        echo "ERROR: Environment variable '$VAR' must not be empty." >&2
        exit 1
    fi
done

# 数据库迁移所需
cp -f "$WORK_DIR/src/config/migrations.lua" "$WORK_DIR/run/migrations.lua"

# 运行配置文件
cp -f "$WORK_DIR/boot.lua" "$WORK_DIR/run/boot.lua"
cp -f "$WORK_DIR/src/config/models.lua" "$WORK_DIR/run/models.lua"
cp -f "$WORK_DIR/src/config/config.lua" "$WORK_DIR/run/config.lua"
cp -f "$WORK_DIR/src/config/mime.types" "$WORK_DIR/run/mime.types"
cp -f "$WORK_DIR/src/config/nginx.conf" "$WORK_DIR/run/nginx.conf"

if ! command -v lapis >/dev/null 2>&1; then
    echo "ERROR: lapis is not installed"
    exit 1
fi

[ ! -s "$RUN_DIR/env.lua" ] && envsubst < "$WORK_DIR/templates/env.lua.template" > "$RUN_DIR/env.lua"

cd "$RUN_DIR" || { echo "ERROR: Failed to change directory!" && exit 1; }
if lapis migrate 2>/dev/null; then
    echo "Migration completed successfully!"
else
    echo "Migration failed!"
    exit 1
fi

if [ "$#" -eq 0 ]; then
    exec lapis server
else
    exec "$@"
fi