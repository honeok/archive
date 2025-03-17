#!/usr/bin/env sh
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# References:
# https://www.cnblogs.com/sparkdev/p/6659629.html
# https://www.cnblogs.com/shaoqunchao/p/7646463.html
# https://github.com/bohai/docker-note/blob/master/doc
# https://www.gnu.org/software/libc/manual/html_node/Termination-Signals.html
# https://github.com/nginxinc/docker-nginx/blob/master/mainline/alpine-slim/docker-entrypoint.sh
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

set \
    -o nounset

export LC_ALL=C

WORK_DIR="/app"
APP_NAME="p8_app_server"

# Save time
case "$DEPLOY_ON" in
    'dev' | 'uat') cooling=10s ;;
    'pro') cooling=60s ;;
    *) echo 'Error: Undefined operating environment.' ; exit 1 ;;
esac

# Server type
case "$SERVER_TYPE" in
    'game'|'log'|'cross'|'gm')
        for script in $(find /docker-entrypoint.d/ -type f -name "*$SERVER_TYPE*.sh"); do
            [ -x "$script" ] && echo "$0: Running $script" && "$script"
        done || { echo "Error: No executable $SERVER_TYPE script found!" && exit 1; }
    ;;
    *) echo "Error: Invalid SERVER_TYPE: $SERVER_TYPE" && exit 1 ;;
esac

_stop() {
    APP_PID=$(pgrep -f $APP_NAME 2>/dev/null)

    if [ -z "$APP_PID" ]; then
        echo "Error: process not found, cannot send SIGUSR2 for saving data." && return
    fi

    # flush signal
    kill -s SIGUSR2 "$APP_PID"
    sleep "$cooling"
}

# Terminate signal capture
# See https://docs.docker.com/reference/cli/docker/container/stop
trap '_stop ; exit 0' TERM INT QUIT

if [ "$#" -eq 0 ]; then
    exec "$WORK_DIR/$APP_NAME"
else
    exec "$@"
fi