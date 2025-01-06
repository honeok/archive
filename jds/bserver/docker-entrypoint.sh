#!/bin/sh

luban_dir="/bserver/config/luban"
health_check_url="http://127.0.0.1:${SERVER_PORT}/api/battle/simulator"

check_health() {
    sleep 10

    if ! curl --silent --max-time 10 --retry 3 --fail "$health_check_url" > /dev/null 2>&1; then
        echo "health check failed: unable to reach $health_check_url"
    fi
}

if [ -d "$luban_dir" ] && [ -z "$(ls -A $luban_dir)" ]; then
    \cp -rf /opt/bserver/config/luban/* $luban_dir/
fi

check_health

exec "$@"