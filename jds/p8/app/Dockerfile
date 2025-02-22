# Description: Dockerfile for building the main p8 process in a containerized environment.
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# References:
# https://github.com/sgerrand/alpine-pkg-glibc
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

FROM alpine:latest

WORKDIR /app

COPY . .

RUN set -ex \
        && apk update && apk upgrade \
        && apk add --no-cache --virtual .build-deps \
            curl \
            tzdata \
        && apk add --no-cache \
            gettext \
        && curl -fsL -o /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
        && curl -fsL -O https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.35-r1/glibc-2.35-r1.apk \
        && apk add glibc-2.35-r1.apk \
        && install -m 755 docker-entrypoint.sh /docker-entrypoint.sh \
        && cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
        && echo "Asia/Shanghai" > /etc/timezone \
        && apk del .build-deps \
        && rm -f \
            Dockerfile \
            docker-entrypoint.sh \
            /etc/apk/keys/sgerrand.rsa.pub \
            glibc-2.35-r1.apk \
        && rm -rf /var/cache/apk/* /tmp/*

VOLUME ["/app/lua", "/app/log", "/app/proto"]

EXPOSE 3340

ENTRYPOINT ["/docker-entrypoint.sh"]