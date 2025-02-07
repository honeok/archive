#!/bin/sh

set \
    -o errexit \
    -o nounset

work_dir="/gm-etl"

if [ -d "$work_dir" ]; then
    cd "$work_dir" || { echo "error: Failed to enter work path!" && exit 1; }
else
    echo "error: Directory $work_dir does not exist, exiting!" && exit 1
fi

[ ! -f "config/gamedb.js" ] && { echo "error: You need to first mount gamedb.js file!" && exit 1; }
[ ! -f "config/setup.js" ] && envsubst < templates/setup.js.template > config/setup.js
[ ! -f "config/task.json" ] && cp -f templates/task.json config/task.json

if [ "$#" -eq 0 ]; then
    exec npm --prefix "$work_dir/" start
else
    exec "$@"
fi