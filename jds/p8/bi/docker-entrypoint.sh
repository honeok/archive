#!/usr/bin/env sh
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

set \
    -o errexit \
    -o nounset

work_dir="/bi"

: "${DB_USER?error: DB_USER missing}"
: "${DB_PASSWORD?error: DB_PASSWORD missing}"
: "${DB_HOST?error: DB_HOST missing}"
: "${DB_PORT?error: DB_PORT missing}"
: "${DB_DATABASE?error: DB_DATABASE missing}"

cd "$work_dir" || { echo "error: Failed to enter work path!" && exit 1; }

[ ! -f ".env" ] && envsubst < templates/template.env > .env
[ ! -f "aerich_env.py" ] && envsubst < templates/aerich_env.template.py > aerich_env.py

if ! command -v aerich >/dev/null 2>&1; then echo "ERROR: aerich command not found!" && exit 1; fi

if mysql -u "$DB_USER" -P "$DB_PORT" -h "$DB_HOST" -p"$DB_PASSWORD" -e "SHOW DATABASES LIKE '$DB_DATABASE';" | grep -q "$DB_DATABASE" || ls -A "$work_dir/migrations/models" >/dev/null 2>&1; then
    aerich migrate
    aerich upgrade
else
    python3 manager.py initdb 2>/dev/null
    aerich init -t aerich_env.TORTOISE_ORM
    aerich init-db
fi

if [ "$#" -eq 0 ]; then
    exec python3 "$work_dir/server.py"
else
    exec "$@"
fi