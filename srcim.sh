#!/usr/bin/env bash
#
# Description: Build Docker image and automatically push it to a container registry.
#
# Copyright (C) 2025 honeok <honeok@duck.com>
# https://www.honeok.com
# https://github.com/honeok/archive/raw/master/s2i.sh
#
# shellcheck disable=all

set \
    -o errexit

script_route=$(realpath "$(dirname "$0")"/$(basename "$0"))
script_dir=$(dirname $(realpath ${script_route}))