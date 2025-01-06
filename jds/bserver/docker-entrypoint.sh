#!/bin/sh

luban_dir="/bserver/config/luban"

if [ -d "$luban_dir" ] && [ -z "$(ls -A $luban_dir)" ]; then
    \cp -rf /opt/bserver/config/luban/* $luban_dir/
fi

exec "$@"