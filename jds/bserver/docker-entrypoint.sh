#!/bin/sh

luban_dir="/bserver/config/luban"
template_luban_dir="/opt/bserver/config/luban"
template_dir="/opt/bserver"

if [ -d "$luban_dir" ] && [ -z "$(ls -A "$luban_dir" 2>/dev/null)" ]; then
    \cp -rf "$template_luban_dir"/* "$luban_dir/"
fi

if [ -d "$template_dir" ]; then
    rm -rf "$template_dir" 2>/dev/null
fi

if [ "$#" -eq 0 ]; then
    exec "/bserver/bserver"
else
    exec "$@"
fi