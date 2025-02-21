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

# shellcheck disable=all

set \
    -o errexit \
    -o nounset

WORK_DIR="/app"
APP_NAME="p8_app_server"
readonly WORK_DIR APP_NAME

_stop() {
    local APP_PID
    APP_PID=$(pgrep -f $APP_NAME)

    if [ -z "$APP_PID" ]; then
        echo "process not found, cannot send SIGUSR2 for saving data."
        return 1
    fi
    # flush
    kill -s SIGUSR2 "$APP_PID"
    sleep 60s
}

# Terminate signal capture
# See https://docs.docker.com/reference/cli/docker/container/stop
trap "_stop; exit 0" SIGTERM SIGINT SIGQUIT

# ....

if [ "$#" -eq 0 ]; then
    exec "$WORK_DIR/$APP_NAME"
else
    exec "$@"
fi