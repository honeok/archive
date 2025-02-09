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

WORKDIR /usr/local/src

RUN set -ex \
        && apk update && apk upgrade \
        && apk add --no-cache gcc g++ make pcre-dev zlib-dev openssl-dev wget bash tar git curl libtool automake \
        && curl -fsL -O https://luarocks.github.io/luarocks/releases/luarocks-3.9.2.tar.gz \
        && tar zxpf luarocks-3.9.2.tar.gz \
        && cd luarocks-3.9.2 \
        && ./configure --prefix=/usr/local/openresty/luajit \
            --with-lua=/usr/local/openresty/luajit \
            --lua-suffix=jit \
            --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 \
        && make -j$(nproc) \
        && make install \
        && cd .. \
        && rm -rfv luarocks* \
        && /usr/local/openresty/luajit/bin/luarocks install lpeg \
        && /usr/local/openresty/luajit/bin/luarocks install luasocket \
        && /usr/local/openresty/luajit/bin/luarocks install lua-resty-jit-uuid \
        && /usr/local/openresty/luajit/bin/luarocks install lua-cjson \
        && /usr/local/openresty/luajit/bin/luarocks install lapis \
        && /usr/local/openresty/luajit/bin/luarocks install lua-resty-redis-connector \
        && /usr/local/openresty/luajit/bin/luarocks install lua-resty-mysql \
        && /usr/local/openresty/luajit/bin/luarocks install lua-resty-mlcache

FROM openresty/openresty:${OPENRESTY_VERSION}

COPY --from=builder /usr/local/openresty /usr/local/openresty

RUN set -ex \
        && apk update && apk upgrade \
        && apk add --no-cache curl \
        && rm -rfv /var/cache/apk/* \
        && mkdir -pv /var/cache/nginx \
        && addgroup -g 1001 -S nginx \
        && adduser -S -D -H -u 1001 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx \
        && chown nginx:nginx /var/cache/nginx \
        && chown -R nginx:nginx /usr/local/openresty /etc/nginx/conf.d /var/run/openresty \
        && sed -i 's/^#user  nobody;/user nginx;/' /usr/local/openresty/nginx/conf/nginx.conf

ENV PATH="/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin:${PATH}" \
    LUA_PATH="/usr/local/openresty/lualib/?.lua;/usr/local/openresty/luajit/share/lua/5.1/?.lua;;" \
    LUA_CPATH="/usr/local/openresty/lualib/?.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so;;" \
    TZ=Asia/Shanghai