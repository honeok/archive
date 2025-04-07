# Description: Dockerfile for building GmAPI in a containerized environment.
#
# Copyright (c) 2025 honeok <honeok@duck.com>
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

ARG BASE_IMAGE_TAG="v0.0.6-alpine"

FROM registry.cn-chengdu.aliyuncs.com/havario/api-base:${BASE_IMAGE_TAG}

WORKDIR /gmapi

COPY . .

RUN set -ex \
        && apk update && apk upgrade \
        && apk add --no-cache \
            gettext \
        && chmod +x build.sh && ./build.sh \
        && install -m 755 docker-entrypoint.sh /docker-entrypoint.sh \
        && install -m 755 healthcheck.sh /usr/local/bin/healthcheck.sh \
        && rm -f build.sh docker-entrypoint.sh healthcheck.sh \
        && rm -rf /var/cache/apk/* /tmp/* \
        && ln -sf /dev/stdout /gmapi/run/logs/access.log \
        && ln -sf /dev/stderr /gmapi/run/logs/error.log

ENV LAPIS_ENVIRONMENT=development

EXPOSE 80 81

ENTRYPOINT [ "/docker-entrypoint.sh" ]

HEALTHCHECK --interval=30s --retries=2 --timeout=5s --start-period=10s \
    CMD /usr/local/bin/healthcheck.sh