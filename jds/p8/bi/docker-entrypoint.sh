#!/bin/sh

set \
    -o errexit \
    -o nounset

work_dir="/bi"

if [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ] || [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_DATABASE" ]; then
    echo "error: required environment variables are missing!"
    exit 1
fi

if ! mysql -u "$DB_USER" -P "$DB_PORT" -h "$DB_HOST" -p"$DB_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS $DB_DATABASE CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;" 2>/dev/null; then
    echo "error: Failed to create the database $DB_DATABASE. Exiting!"
    exit 1
fi

if [ -d "$work_dir" ]; then
    cd "$work_dir" || { echo "error: Failed to enter work path!" && exit 1; }
else
    echo "error: Directory $work_dir does not exist, exiting!" && exit 1
fi

[ ! -f ".env" ] && envsubst < templates/.env.template > .env
[ ! -f "aerich_env.py" ] && envsubst < templates/aerich_env.py.template > aerich_env.py

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