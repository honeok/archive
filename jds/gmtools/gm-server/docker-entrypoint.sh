#!/bin/sh

set \
    -o errexit \
    -o nounset

work_dir="/gm-server"

if [ -d "$work_dir" ]; then
    cd "$work_dir" || { echo "Failed to enter work path!" && exit 1; }
    if [ ! -f config/gamedb.js ]; then
        echo "error: You need to first mount gamedb.js file!"
        exit 1
    fi
    if [ ! -f config/setup.js ]; then
        envsubst < templates/setup.js.template > config/setup.js
    fi
    if [ ! -f config/obs.js ]; then
        envsubst < templates/obs.js.template > config/obs.js
    fi
else
    echo "Directory $work_dir does not exist, exiting!"
    exit 1
fi

if [ "$#" -eq 0 ]; then
    exec npm --prefix "$work_dir/" start
else
    exec "$@"
fi