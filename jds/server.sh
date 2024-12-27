#!/usr/bin/env bash

start() {
    if ! running; then
        ulimit -c unlimited
        nohup "$(pwd)"/p8_app_server > nohup.txt 2>&1 &
        echo $! > pid.txt
        echo "server start: $(cat pid.txt)"
    else
        echo "server running: $(cat pid.txt)"
    fi
}

stop() {
    if running; then
        kill -SIGKILL "$(cat pid.txt)"
        echo "server stop: $(cat pid.txt)"
        rm -f pid.txt
    else
        echo "server stopped"
    fi
}

reload() {
    if running; then
        kill -SIGUSR1 "$(cat pid.txt)"
        echo "server reload: $(cat pid.txt)"
    else
        echo "server stopped"
    fi
}

flush() {
    if running; then
        kill -SIGUSR2 "$(cat pid.txt)"
        echo "server flush: $(cat pid.txt)"
    else
        echo "server stopped"
    fi
}

status() {
    if running; then
        echo "server running: $(cat pid.txt)"
    else
        echo "server stopped"
    fi
}

running() {
    $(test -f "pid.txt") && $(test -f "/proc/$(cat pid.txt)/comm") && $(test $(cat "/proc/$(cat pid.txt)/comm") == "p8_app_server")
}

case ${1} in
    "start")
        start
    ;;
    "stop")
        stop
    ;;
    "restart")
        stop
        start
    ;;
    "reload")
        reload
    ;;
    "flush")
        flush
    ;;
    "status")
        status
    ;;
    *)
        echo "./server.sh start | stop | restart | reload | flush | status"
    ;;
esac