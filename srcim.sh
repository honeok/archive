#!/usr/bin/env bash
#
# Description: Build Docker image and automatically push it to a container registry.
#
# Original Author: Jimmy 2021.10 @Next eng
# Forked and Modified By: 2021 - 2025 honeok <honeok@duck.com>
#
# https://www.honeok.com
# https://github.com/honeok/archive/raw/master/srcim.sh
#
# The name was inspired by ChatGPT.
# Special thanks to my mentor Zhenqiang Zhang for guidance and support.

# shellcheck disable=all

set \
    -o errexit

SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
SCRIPT_DIR=$(dirname $(realpath ${SCRIPT}))