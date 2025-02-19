# Description: Dockerfile for building GameAPI in a containerized environment.
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

ARG BASE_IMAGE_TAG="v0.0.6-alpine"

FROM registry.cn-chengdu.aliyuncs.com/havario/api-base:${BASE_IMAGE_TAG}

WORKDIR /gameapi

COPY . .

RUN set -ex \
        && apk update && apk upgrade \
        && apk add --no-cache \
            gettext \
        && chmod +x build.sh && ./build.sh \
        && install -m 755 docker-entrypoint.sh /docker-entrypoint.sh \
        && rm -f build.sh docker-entrypoint.sh Dockerfile \
        && rm -rf /var/cache/apk/* /tmp/* \
        && ln -sf /dev/stdout /gameapi/run/logs/access.log \
        && ln -sf /dev/stderr /gameapi/run/logs/error.log

ENV LAPIS_ENVIRONMENT=development

ENTRYPOINT [ "/docker-entrypoint.sh" ]