# Description: Dockerfile for building the main p8 process in a containerized environment.
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

FROM alpine:latest

WORKDIR /app

COPY . .

RUN set -ex \
        && apk update && apk upgrade \
        && apk add --no-cache \
            gettext \
            tzdata \
        && install -m 755 docker-entrypoint.sh /docker-entrypoint.sh \
        && cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
        && echo "Asia/Shanghai" > /etc/timezone \
        && apk del tzdata \
        && rm -f Dockerfile docker-entrypoint.sh

VOLUME [ "/app/lua", "/app/log" , "/app/proto"]

EXPOSE 3340

ENTRYPOINT [ "/docker-entrypoint.sh" ]