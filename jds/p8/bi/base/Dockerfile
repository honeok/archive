# Description: Dockerfile for building the base image for the BI containerized environment.
#
# Copyright (c) 2025 honeok <honeok@duck.com>
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

# BASE_VER 'v0.0.8-alpine'

FROM python:3.9.20-alpine3.20

COPY requirements.txt .

RUN set -ex \
        && apk update && apk upgrade \
        && apk add --no-cache \
            gcc \
            gettext \
            libffi-dev \
            musl-dev \
            python3-dev \
            tzdata \
        && python3 -m pip install --no-cache-dir -r requirements.txt \
        && cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
        && echo "Asia/Shanghai" > /etc/timezone \
        && apk del tzdata \
        && rm -f requirements.txt \
        && rm -rf /var/cache/apk/* /tmp/*