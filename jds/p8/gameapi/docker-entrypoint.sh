#!/usr/bin/env sh
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

work_dir="/gameapi"
run_dir="$work_dir/run"

if ! hash lapis >/dev/null 2>&1; then
    echo "ERROR: lapis is not installed"
    exit 1
fi

[ ! -s "$run_dir/config.lua" ] && envsubst < "$work_dir/templates/config.lua.template" > "$run_dir/config.lua"

cd "$run_dir" || { echo "ERROR: Failed to change directory!" && exit 1; }
if lapis migrate 2>/dev/null; then
    echo "Migration completed successfully!"
else
    echo "Migration failed!"
    exit 1
fi

if [ "$#" -eq 0 ]; then
    exec "lapis server"
else
    exec "$@"
fi