#!/usr/bin/env sh
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# References:
# https://www.cnblogs.com/sparkdev/p/6659629.html
# https://www.cnblogs.com/shaoqunchao/p/7646463.html
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

# shellcheck disable=all

# 终止信号捕获
trap "_exit" SIGQUIT SIGTERM EXIT

