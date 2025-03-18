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
        && install -m 755 docker-entrypoint.sh /docker-entrypoint.sh \
        && install -m 755 server.sh /usr/local/bin/server.sh \
        && apt-get update \
        && apt-get install -y tzdata \
        && rm -f /etc/localtime \
        && ln /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
        && apt-get remove --purge -y tzdata \
# Bring in gettext so we can get `envsubst`, then throw
# the rest away. To do this, we need to install `gettext`
# then move `envsubst` out of the way so `gettext` can
# be deleted completely, then move `envsubst` back.
        && apt-get install -y gettext \
        && mv /usr/bin/envsubst /tmp/ \
        && apt-get remove --purge -y gettext \
        && mv /tmp/envsubst /usr/bin/ \
        && apt-get clean \
# clear script
        && rm -f docker-entrypoint.sh server.sh \
        && rm -rf /var/lib/apt/lists/* /tmp/* \
# create a docker-entrypoint.d directory
        && mkdir /docker-entrypoint.d

EXPOSE 3340

ENTRYPOINT [ "/docker-entrypoint.sh" ]