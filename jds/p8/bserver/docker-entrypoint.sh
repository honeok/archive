#!/bin/sh

luban_config_dir="/bserver/config/luban"
template_luban_config_dir="/opt/config/luban"

if [ -d "$luban_config_dir" ] && [ -z "$(ls -A "$luban_config_dir" 2>/dev/null)" ]; then
    \cp -rf "$template_luban_config_dir"/* "$luban_config_dir/"
fi

if [ -d "$template_luban_config_dir" ]; then
    rm -rf "$template_luban_config_dir" 2>/dev/null
fi

if [ "$#" -eq 0 ]; then
    exec "/bserver/bserver"
else
    exec "$@"
fi