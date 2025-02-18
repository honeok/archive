# Description: Dockerfile for building GameAPI in a containerized environment.
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

ARG BASE_IMAGE_TAG="v0.0.5-alpine"

FROM registry.cn-chengdu.aliyuncs.com/havario/api-base:${BASE_IMAGE_TAG}

WORKDIR /gameapi

COPY . .

RUN set -ex \
        && apk update && apk upgrade \
        && install -m 755 docker-entrypoint.sh /docker-entrypoint.sh \
        && rm -f docker-entrypoint.sh Dockerfile \
        && rm -rf /var/cache/apk/* /tmp/*

ENV LAPIS_ENVIRONMENT=${LAPIS_ENVIRONMENT:-"development"}

ENTRYPOINT [ "/docker-entrypoint.sh" ]