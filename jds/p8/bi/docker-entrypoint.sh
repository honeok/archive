#!/bin/sh

set \
    -o errexit \
    -o nounset

work_dir="/bi"

: "${DB_USER?error: DB_USER missing}"
: "${DB_PASSWORD?error: DB_PASSWORD missing}"
: "${DB_HOST?error: DB_HOST missing}"
: "${DB_PORT?error: DB_PORT missing}"
: "${DB_DATABASE?error: DB_DATABASE missing}"

if [ -d "$work_dir" ]; then
    cd "$work_dir" || { echo "error: Failed to enter work path!" && exit 1; }
else
    echo "error: Directory $work_dir does not exist, exiting!" && exit 1
fi

[ ! -f ".env" ] && envsubst < templates/.env.template > .env
[ ! -f "aerich_env.py" ] && envsubst < templates/aerich_env.py.template > aerich_env.py

set +o errexit
if ! python3 manager.py initdb >/dev/null 2>&1; then
    echo "Database $DB_DATABASE already exists. Skipping initialization."
else
    echo "Initializing database $DB_DATABASE"
fi
set -o errexit

if command -v aerich >/dev/null 2>&1; then
    aerich init -t aerich_env.TORTOISE_ORM
    aerich init-db
else
    echo "error: aerich command not found!"
    exit 1
fi

if [ "$#" -eq 0 ]; then
    exec python3 "$work_dir/server.py"
else
    exec "$@"
fi