#!/usr/bin/env sh
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# References:
# https://www.cnblogs.com/sparkdev/p/6659629.html
# https://www.cnblogs.com/shaoqunchao/p/7646463.html
# https://github.com/bohai/docker-note/blob/master/doc
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

set \
    -o errexit \
    -o nounset

WORK_DIR="/app"
APP_NAME="p8_app_server"
readonly WORK_DIR APP_NAME

# Save time
case "$DEPLOY_ON" in
    dev | uat)
        cooling=8s
    ;;
    pro)
        cooling=60s
    ;;
    *)
        echo "Undefined operating environment."
        exit 1
    ;;
esac

# server.app.lua
: "${DOMAIN?error: DOMAIN missing}"
: "${LOCAL_ADDRESS?error: LOCAL_ADDRESS missing}"
: "${DISCOVER_NODE1?error: DISCOVER_NODE1 missing}"
: "${DISCOVER_NODE2?error: DISCOVER_NODE2 missing}"
: "${DISCOVER_NODE3?error: DISCOVER_NODE3 missing}"
: "${GAMEDB_HOST?error: GAMEDB_HOST missing}"
: "${GAMEDB_USER?error: GAMEDB_USER missing}"
: "${GAMEDB_PASSWORD?error: GAMEDB_PASSWORD missing}"
: "${GAMEDB_DATABASE?error: GAMEDB_DATABASE missing}"
: "${GROUP_ID?error: GROUP_ID missing}"
: "${AREA_ID?error: AREA_ID missing}"
: "${PAY_NOTIFY?error: PAY_NOTIFY missing}"
# server.log.ini
: "${LOG_LEVEL?error: LOG_LEVEL missing}"
# zones.lua
: "${ZONES_NUM?error: ZONES_NUM missing}"
: "${ZONE_VALUE?error: ZONE_VALUE missing}"
# open_time.lua
: "${OPEN_SERVER_TIME?error: OPEN_SERVER_TIME missing}"

_stop() {
    APP_PID=$(pgrep -f $APP_NAME)

    if [ -z "$APP_PID" ]; then
        echo "process not found, cannot send SIGUSR2 for saving data."
        return 0
    fi

    # flush
    kill -s SIGUSR2 "$APP_PID"
    sleep "$cooling"
}

# Terminate signal capture
# See https://docs.docker.com/reference/cli/docker/container/stop
trap "_stop; exit 0" TERM INT QUIT

# Config generate
envsubst < templates/server.app.template.lua > etc/server.app.lua
envsubst < templates/server.log.template.ini > etc/server.log.ini
envsubst < templates/zones.template.lua > etc/zones.lua
envsubst < templates/open_time.template.lua > lua/config/open_time.lua
envsubst < templates/server.template.lua > lua/config/server.lua

if [ "$#" -eq 0 ]; then
    exec "$WORK_DIR/$APP_NAME"
else
    exec "$@"
fi