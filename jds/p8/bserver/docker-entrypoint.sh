#!/bin/sh

luban_config_dir="/bserver/config/luban"
luban_config_dir_temp="/bserver/config/luban_temp"

if [ -d "$luban_config_dir" ] && [ -z "$(ls -A "$luban_config_dir" 2>/dev/null)" ]; then
    cp -rf "$luban_config_dir_temp"/* "$luban_config_dir/"
fi

if [ "$#" -eq 0 ]; then
    exec "/bserver/bserver"
else
    exec "$@"
fi