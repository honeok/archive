#!/usr/bin/env bash
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#      __     __       _____
#  __ / / ___/ /  ___ / ___/ ___ _  __ _  ___
# / // / / _  /  (_-</ (_ / / _ `/ /  ' \/ -_)
# \___/  \_,_/  /___/\___/  \_,_/ /_/_/_/\__/
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License, version 3 or later.
#
# This program is distributed WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# See the LICENSE file or <https://www.gnu.org/licenses/> for full license terms.

SCRIPT_DIR=$(realpath "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)")
APP_NAME="p8_app_server"

_start() {
    if ! running; then
        ulimit -c unlimited
        nohup "$SCRIPT_DIR/$APP_NAME" > nohup.txt 2>&1 &
        echo $! > "$SCRIPT_DIR"/pid.txt
        echo "server start: $(< "$SCRIPT_DIR"/pid.txt)"
    else
        echo "server running: $(< "$SCRIPT_DIR"/pid.txt)"
    fi
}

_stop() {
    if running; then
        kill -s SIGKILL "$(< "$SCRIPT_DIR"/pid.txt)"
        echo "server stop: $(< "$SCRIPT_DIR"/pid.txt)"
        rm -f pid.txt
    else
        echo "server stopped"
    fi
}

_reload() {
    if running; then
        kill -s SIGUSR1 "$(< "$SCRIPT_DIR"/pid.txt)"
        echo "server reload: $(< "$SCRIPT_DIR"/pid.txt)"
    else
        echo "server stopped"
    fi
}

_flush() {
    if running; then
        kill -s SIGUSR2 "$(< "$SCRIPT_DIR"/pid.txt)"
        echo "server flush: $(< "$SCRIPT_DIR"/pid.txt)"
    else
        echo "server stopped"
    fi
}

_status() {
    if running; then
        echo "server running: $(< "$SCRIPT_DIR"/pid.txt)"
    else
        echo "server stopped"
    fi
}

_running() {
    [[ -f "$SCRIPT_DIR/pid.txt" ]] && [[ -f "/proc/$(< "$SCRIPT_DIR/pid.txt")/comm" ]] && [[ $(< "/proc/$(< "$SCRIPT_DIR/pid.txt")/comm") =~ $APP_NAME ]]
}

case "$1" in
    'start' )
        _start
    ;;
    'stop' )
        _stop
    ;;
    'restart' )
        _stop
        _start
    ;;
    'reload' )
        _reload
    ;;
    'flush' )
        _flush
    ;;
    'status' )
        _status
    ;;
    *)
        echo "USAGE: ./server.sh start | stop | restart | reload | flush | status"
    ;;
esac