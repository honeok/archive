# Description: Dockerfile for building the BI containerized image
#
# Copyright (c) 2025 honeok <honeok@duck.com>
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

ARG BASE_IMAGE_TAG="v0.0.7-alpine"

FROM registry.cn-chengdu.aliyuncs.com/havario/bi-base:${BASE_IMAGE_TAG}

WORKDIR /bi

COPY . .

RUN set -ex \
        && apk update && apk upgrade \
        && install -m 755 docker-entrypoint.sh /docker-entrypoint.sh \
        && rm -f docker-entrypoint.sh .env aerich_env.py \
        && rm -rf /var/cache/apk/* /tmp/* logs/*

EXPOSE 8000

ENTRYPOINT [ "/docker-entrypoint.sh" ]