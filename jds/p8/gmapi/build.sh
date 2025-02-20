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

[ -d "${RUN_DIR:?}" ] && find "$RUN_DIR" -mindepth 1 -delete

# 运行环境准备
mkdir -p \
    "$RUN_DIR/logs" \
    "$RUN_DIR/temp/client-body" \
    "$RUN_DIR/temp/proxy" \
    "$RUN_DIR/temp/fastcgi" \
    "$RUN_DIR/temp/uwsgi" \
    "$RUN_DIR/temp/scgi"