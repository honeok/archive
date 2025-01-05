# Dockerfile from bserver containerization construction
# Copyright (C) 2025 honeok <honeok@duck.com>

ARG ROCKY_VERSION=9.3
FROM rockylinux:${ROCKY_VERSION}

LABEL maintainer="honeok <honeok@duck.com>"

WORKDIR /

COPY bserver bserver
COPY App.json.template /bserver/config/App.json.template

RUN dnf -y update && \
    dnf -y install gettext procps && \
    dnf clean all && \
    chmod +x /bserver/bserver

ENV SERVER_PORT="18081"
ENV ASSERT_PATH="/bserver/config/luban/"

RUN envsubst < /bserver/config/App.json.template > /bserver/config/App.json && \
    rm -f /bserver/config/App.json.template

EXPOSE ${BSERVER_PORT}

CMD ["/bserver/bserver"]
