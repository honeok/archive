# Description: Dockerfile for building the main p8 process in a containerized environment.
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# References:
# https://www.gnu.org/software/libc/manual/html_node/Termination-Signals.html
# https://github.com/nginxinc/docker-nginx/blob/master/mainline/alpine-slim/Dockerfile
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

FROM registry.cn-chengdu.aliyuncs.com/honeok/ubuntu:22.04

WORKDIR /app

COPY . .

RUN set -ex \
        && export DEBIAN_FRONTEND=noninteractive \
        && apt-get update \
        && apt-get install -y tzdata \
        && rm -f /etc/localtime \
        && ln /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
        && apt-get remove --purge -y tzdata \
        && apt-get install -y gettext \
        && mv /usr/bin/envsubst /tmp/ \
        && apt-get remove --purge -y gettext \
        && mv /tmp/envsubst /usr/bin/ \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/* /tmp/*

EXPOSE 3340

ENTRYPOINT [ "/docker-entrypoint.sh" ]

STOPSIGNAL SIGTERM