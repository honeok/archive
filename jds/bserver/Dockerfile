# Dockerfile from bserver containerization construction
# Copyright (C) 2025 honeok <honeok@duck.com>

FROM alpine:latest

LABEL maintainer="honeok <honeok@duck.com>"

WORKDIR /

COPY bserver /bserver

COPY App.json.template /bserver/config/App.json.template

RUN apk update && \
    apk add --no-cache bash curl gettext && \
    rm -rf /var/cache/apk/* && \
    chmod +x /bserver/bserver

ENV ASSERT_PATH="/bserver/config/luban"

RUN envsubst < /bserver/config/App.json.template > /bserver/config/App.json

EXPOSE 18081

CMD ["/bserver/bserver"]