#!/usr/bin/env sh
#
# Description: Script for P8 app signal control, based on server.sh branch.
#
# Copyright (C) 2025 The JdsGame. All rights reserved.
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

set \
    -o errexit \
    -o nounset

APP_NAME='p8_app_server'

if [ "$(pgrep -f "$APP_NAME" | wc -l)" -gt 1 ]; then
    echo 'Error: Multiple processes found or none available.' && exit 1
else
    APP_PID=$(pgrep -f "$APP_NAME")
fi

case "$1" in
    'reload')
        kill -s SIGUSR1 "$APP_PID"
        echo "server reload: $APP_PID"
    ;;
    'flush')
        kill -s SIGUSR2 "$APP_PID"
        echo "server flush: $APP_PID"
    ;;
    *)
        echo 'Error: Invalid parameter.' && exit 1
    ;;
esac