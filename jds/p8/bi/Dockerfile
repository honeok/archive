# Description: Dockerfile for building the BI containerized image
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

ARG BASE_IMAGE_TAG="v0.0.4-alpine"

FROM registry.cn-chengdu.aliyuncs.com/havario/bi-base:${BASE_IMAGE_TAG}

WORKDIR /bi

COPY . .

RUN set -ex \
        && country=$(wget -qO- https://ipinfo.io/country) \
        && if [ "$country" = "CN" ]; then sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories; fi \
        && apk update && apk upgrade \
        && install -m 755 docker-entrypoint.sh /docker-entrypoint.sh \
        && rm -f docker-entrypoint.sh Dockerfile .env aerich_env.py \
        && rm -rf /var/cache/apk/* /tmp/* logs/*

EXPOSE 8000

ENTRYPOINT [ "/docker-entrypoint.sh" ]