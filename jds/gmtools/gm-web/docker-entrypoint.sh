#!/bin/sh

set \
    -o errexit \
    -o nounset

work_dir="/gm-web"

if [ -d "$work_dir" ]; then
    cd "$work_dir" || { echo "error: Failed to enter work path!" && exit 1; }
else
    echo "error: Directory $work_dir does not exist, exiting!" && exit 1
fi

[ ! -f "src/globle/setup.js" ] && { echo "error: You need to first mount setup.js file!" && exit 1; }
[ ! -f "index.html" ] && envsubst < index.html.template > index.html
[ ! -f "config/dev.env.js" ] && envsubst < templates/dev.env.js.template > config/dev.env.js
[ ! -f "config/index.js" ] && envsubst < templates/index.js.template > config/index.js
[ ! -f "config/prod.env.js" ] && envsubst < templates/prod.env.js.template > config/prod.env.js

if [ "$#" -eq 0 ]; then
    exec npm --prefix "$work_dir/" start
else
    exec "$@"
fi