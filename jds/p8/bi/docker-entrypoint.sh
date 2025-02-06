#!/bin/sh

work_dir="/bi"

if [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ] || [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_DATABASE" ]; then
    echo "required environment variables are missing!"
    exit 1
fi

if [ -d "$work_dir" ]; then
    envsubst < .env.template > .env
    envsubst < aerich_env.py.template > aerich_env.py

    aerich init -t aerich_env.TORTOISE_ORM
    aerich init-db
else
    echo "Directory $work_dir does not exist, exiting!"
    exit 1
fi

if [ "$#" -eq 0 ]; then
    exec python3 "$work_dir/server.py"
else
    exec "$@"
fi