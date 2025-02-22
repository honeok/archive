# Description: Dockerfile for building the bserver containerized environment
#
# Copyright (C) 2024 - 2025 honeok <honeok@duck.com>
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

FROM alpine:latest

WORKDIR /bserver

COPY . .

RUN set -ex \
        && apk update && apk upgrade \
        && apk add --no-cache \
            libstdc++ \
            libc6-compat \
            tzdata \
        && chmod +x bserver \
        && install -m 755 docker-entrypoint.sh /docker-entrypoint.sh \
        && cp -f templates/App.template.json config/App.json \
        && cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
        && echo "Asia/Shanghai" > /etc/timezone \
        && apk del tzdata \
        && rm -f Dockerfile docker-entrypoint.sh \
        && rm -rf config/luban_temp \
        && rm -rf /var/cache/apk/* templates logs BattleSimulator \
        && mkdir -p logs BattleSimulator config/luban_temp \
        && cp -rf config/luban/* config/luban_temp/

EXPOSE 8080

ENTRYPOINT [ "/docker-entrypoint.sh" ]