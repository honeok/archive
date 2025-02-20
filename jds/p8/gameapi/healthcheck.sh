#!/usr/bin/env sh
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

PORT="80"
COUNT="0"
RETRY="2"

until nc -z -w 5 127.0.0.1 "$PORT"; do
    COUNT=$(( COUNT + 1 ))

    echo "Health check failed. Retrying ($COUNT/2)"
    if [ "$COUNT" -ge "$RETRY" ]; then
        echo "Service on port $PORT is not responding, exiting!"
        exit 1
    fi
    sleep 10
done

echo "Service on port $PORT is healthy!"
exit 0