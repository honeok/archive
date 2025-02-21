#!/usr/bin/env sh
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# References:
# https://docs.docker.net.cn/reference/cli/docker/container/stop/
# https://www.cnblogs.com/sparkdev/p/6659629.html
# https://www.cnblogs.com/shaoqunchao/p/7646463.html
# https://github.com/bohai/docker-note/blob/master/doc
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

# shellcheck disable=all

# Terminate signal capture
# https://www.linuxjournal.com/content/bash-trap-command
# https://en.wikipedia.org/wiki/Signal_(IPC)
trap "_stop" SIGQUIT SIGTERM EXIT

_stop() {
    kill -s SIGUSR2 $(pgrep -f p8_app_server)
}