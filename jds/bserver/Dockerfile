# Dockerfile from bserver containerization construction
# Copyright (C) 2025 honeok <honeok@duck.com>

ARG ROCKY_VERSION=9.3
FROM rockylinux:${ROCKY_VERSION}

LABEL maintainer="honeok <honeok@duck.com>"

WORKDIR /

COPY . .

ENV BSERVER_PORT="8080" TZ=Asia/Shanghai

RUN set -ex \
    && dnf -y update && dnf install -y gettext procps \
    && chmod +x /bserver/bserver && install -m 755 docker-entrypoint.sh /usr/local/bin/entrypoint.sh \
    && ln -sf /usr/local/bin/entrypoint.sh entrypoint.sh \
    && envsubst < App.json.template > /bserver/config/App.json \
    && rm -f App.json.template Dockerfile docker-entrypoint.sh build.sh \
    && dnf remove -y gettext && dnf clean all && rm -rf /var/cache/dnf/* \
    && rm -rf /opt/bserver \
    && mkdir -p /opt/bserver/config/luban \
    && cp -r /bserver/config/luban/* /opt/bserver/config/luban/ \
    && rm -rf /bserver/logs/* /bserver/BattleSimulator/*

EXPOSE ${BSERVER_PORT}

ENTRYPOINT ["entrypoint.sh"]