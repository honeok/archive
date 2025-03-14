# Description: Dockerfile for building the gm-server container
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#      __     __       _____
#  __ / / ___/ /  ___ / ___/ ___ _  __ _  ___
# / // / / _  /  (_-</ (_ / / _ `/ /  ' \/ -_)
# \___/  \_,_/  /___/\___/  \_,_/ /_/_/_/\__/
#
# License Information:
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License, version 3 or later.
#
# This program is distributed WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <https://www.gnu.org/licenses/>.

ARG BASE_IMAGE_TAG"16.20.2-alpine"

FROM node:${BASE_IMAGE_TAG}

WORKDIR /gm-server

COPY . .

RUN set -ex \
        && apk update && apk upgrade \
        && apk add --no-cache \
            gettext \
            tzdata \
        && install -m 755 docker-entrypoint.sh /docker-entrypoint.sh \
        && rm -rf node_modules upload logs config \
        && npm install \
        && cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
        && echo "Asia/Shanghai" > /etc/timezone \
        && apk del tzdata \
        && rm -rf /var/cache/apk/* \
        && mkdir -p upload logs config \
        && rm -f Dockerfile docker-entrypoint.sh

EXPOSE 3000

ENTRYPOINT [ "/docker-entrypoint.sh" ]