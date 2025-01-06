#!/bin/sh

luban_dir="/bserver/config/luban"

if [ -d "$luban_dir" ] && [ -z "$(ls -A "$luban_dir" 2>/dev/null)" ]; then
    \cp -rf /opt/bserver/config/luban/* "$luban_dir/"
fi

if [ -d "/opt/bserver" ]; then
    rm -rf /opt/bserver >/dev/null 2>&1
fi

exec "$@"