# Description: Dockerfile for the gameapi basic environment based on Alpine
#
# Copyright (C) 2024 - 2025 honeok <honeok@duck.com>
#      __     __       _____
#  __ / / ___/ /  ___ / ___/ ___ _  __ _  ___
# / // / / _  /  (_-</ (_ / / _ `/ /  ' \/ -_)
# \___/  \_,_/  /___/\___/  \_,_/ /_/_/_/\__/
#
# References:
# https://github.com/luarocks/luarocks/wiki/Download
# https://github.com/openresty/docker-openresty/blob/master/alpine/Dockerfile
# https://github.com/nginxinc/docker-nginx/blob/master/mainline/alpine-slim/Dockerfile
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

ARG OPENRESTY_VERSION=1.27.1.1-alpine

FROM openresty/openresty:${OPENRESTY_VERSION} AS builder

ARG LUAROCKS_VERSION=3.9.2

RUN set -ex \
        && apk update && apk upgrade \
        && apk add --no-cache --virtual .build-deps \
            gcc \
            g++ \
            make \
            pcre-dev \
            zlib-dev \
            openssl-dev \
            curl \
            wget \
            git \
            libtool \
            automake \
        && cd /tmp/ \
        && curl -fsL -O https://luarocks.github.io/luarocks/releases/luarocks-${LUAROCKS_VERSION}.tar.gz \
        && tar zxpf luarocks-${LUAROCKS_VERSION}.tar.gz \
        && cd luarocks-${LUAROCKS_VERSION} \
        && ./configure --prefix=/usr/local/openresty/luajit \
            --with-lua=/usr/local/openresty/luajit \
            --lua-suffix=jit \
            --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 \
        && make -j$(nproc) \
        && make -j$(nproc) install \
        && cd / \
        && /usr/local/openresty/luajit/bin/luarocks install lpeg \
        && /usr/local/openresty/luajit/bin/luarocks install luasocket \
        && /usr/local/openresty/luajit/bin/luarocks install lua-resty-jit-uuid \
        && /usr/local/openresty/luajit/bin/luarocks install lua-cjson \
        && /usr/local/openresty/luajit/bin/luarocks install lapis \
        && /usr/local/openresty/luajit/bin/luarocks install lua-resty-redis-connector \
        && /usr/local/openresty/luajit/bin/luarocks install lua-resty-mysql \
        && /usr/local/openresty/luajit/bin/luarocks install lua-resty-mlcache \
        && rm -rf /tmp/* \
        && apk del .build-deps

FROM openresty/openresty:${OPENRESTY_VERSION}

COPY --from=builder /usr/local/openresty /usr/local/openresty

RUN set -ex \
        && apk update && apk upgrade \
        && apk add --no-cache tzdata \
        && cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
        && echo "Asia/Shanghai" > /etc/timezone \
        && apk del tzdata \
        && rm -rf /var/cache/apk/* \
        && mkdir -p /var/cache/nginx \
        && addgroup -g 1001 -S nginx \
        && adduser -S -D -H -u 1001 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx \
        && chown -R nginx:nginx /usr/local/openresty /etc/nginx /var/run/openresty /var/cache/nginx \
        && sed -i 's/^#user  nobody;/user  nginx;/' /usr/local/openresty/nginx/conf/nginx.conf

ENV PATH=$PATH:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin
ENV LUA_PATH=/usr/local/openresty/lualib/?.lua;/usr/local/openresty/luajit/share/lua/5.1/?.lua;;
ENV LUA_CPATH=/usr/local/openresty/lualib/?.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so;;