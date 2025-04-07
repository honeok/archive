#!/usr/bin/env sh
#
# Copyright (c) 2025 honeok <honeok@duck.com>
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

luban_config_dir="/bserver/config/luban"
luban_config_dir_temp="/bserver/config/luban_temp"

if [ -d "$luban_config_dir" ] && [ -z "$(ls -A "$luban_config_dir" 2>/dev/null)" ]; then
    command cp -rf "$luban_config_dir_temp"/* "$luban_config_dir/"
fi

if [ "$#" -eq 0 ]; then
    exec "/bserver/bserver"
else
    exec "$@"
fi