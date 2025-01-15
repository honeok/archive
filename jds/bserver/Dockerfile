# Dockerfile from bserver containerization construction
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# https://github.com/honeok/archive/raw/master/jds/bserver/Dockerfile

ARG ROCKY_VERSION=9.3
FROM rockylinux:${ROCKY_VERSION}

LABEL maintainer="honeok <honeok@duck.com>"

WORKDIR /bserver

COPY . .

ENV BSERVER_PORT="8080" TZ=Asia/Shanghai

RUN set -ex \
    && dnf install -y gettext procps \
    && chmod +x bserver && install -m 755 docker-entrypoint.sh /docker-entrypoint.sh \
    && envsubst < App.json.template > config/App.json \
    && rm -f App.json.template Dockerfile \
    && dnf remove -y gettext && dnf clean all && rm -rf /var/cache/dnf/* \
    && rm -rf /opt/config/luban \
    && mkdir -p /opt/config/luban \
    && cp -r config/luban/* /opt/config/luban/ \
    && rm -rfv logs/* BattleSimulator/*

EXPOSE ${BSERVER_PORT}

ENTRYPOINT ["/docker-entrypoint.sh"]