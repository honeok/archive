#!/usr/bin/env bash
#
# Description: Build Docker image and automatically push it to a container registry.
#
# Copyright (C) 2021 - 2025 honeok <honeok@duck.com>
# https://www.honeok.com
# https://github.com/honeok/archive/raw/master/srcim.sh
#
# The name was inspired by ChatGPT.
# Special thanks to my mentor Zhenqiang Zhang for guidance and support.

# shellcheck disable=all

set \
    -o errexit

script_route=$(realpath "$(dirname "$0")"/$(basename "$0"))
script_dir=$(dirname $(realpath ${script_route}))