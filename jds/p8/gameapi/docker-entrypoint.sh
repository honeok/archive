#!/usr/bin/env sh
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

set \
    -o errexit \
    -o nounset

work_dir="/gameapi"
run_dir="$work_dir/run"

check_vars="MYSQL_HOST MYSQL_USER MYSQL_PASSWORD MYSQL_DATABASE MYSQL_TIMEZONE REDIS_HOST REDIS_DATABASE"

for var in $check_vars; do
    dev_var="DEV_$var"
    pro_var="PRO_$var"

    eval "dev_val=\${$dev_var}"
    eval "pro_val=\${$pro_var}"

    if [ -z "$dev_val" ] && [ -z "$pro_val" ]; then
        echo "ERROR: Both $dev_var and $pro_var are missing."
        exit 1
    fi
done

if ! command -v lapis >/dev/null 2>&1; then
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