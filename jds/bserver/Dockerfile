# Dockerfile from bserver containerization construction
# Copyright (C) 2025 honeok <honeok@duck.com>

FROM rockylinux:9.3

LABEL maintainer="honeok <honeok@duck.com>"

WORKDIR /data

COPY bserver bserver

COPY App.json.template /data/bserver/config/App.json.template

RUN dnf -y update && \
    dnf -y install gettext && \
    dnf clean all && \
    chmod +x /data/bserver/bserver

ENV ASSERT_PATH="/data/bserver/config/luban/"

RUN envsubst < /data/bserver/config/App.json.template > /data/bserver/config/App.json && \
    rm -f /data/bserver/config/App.json.template

EXPOSE 18081

CMD ["/data/bserver/bserver"]