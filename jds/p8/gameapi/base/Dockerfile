# Description: Dockerfile for the gameapi basic environment based on Alpine
#
# Copyright (C) 2024 - 2025 honeok <honeok@duck.com>
#      __     __       _____                  
#  __ / / ___/ /  ___ / ___/ ___ _  __ _  ___ 
# / // / / _  /  (_-</ (_ / / _ `/ /  ' \/ -_)
# \___/  \_,_/  /___/\___/  \_,_/ /_/_/_/\__/ 
#                                             
# References:
# - https://github.com/luarocks/luarocks/wiki/Download
# - https://github.com/nginxinc/docker-nginx/blob/master/mainline/alpine-slim/Dockerfile
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

FROM openresty/openresty:1.27.1.1-alpine AS builder

WORKDIR /app

COPY . .

RUN chmod +x build_dep.sh && sh build_dep.sh \
    && apk update \
    && apk add --no-cache gcc g++ make pcre-dev zlib-dev openssl-dev wget bash tar git libtool automake \
    && rm -rf /var/cache/apk/*

RUN curl -L https://luarocks.org/releases/luarocks-3.9.2.tar.gz -o /tmp/luarocks-3.9.2.tar.gz \
    && tar zxpf /tmp/luarocks-3.9.2.tar.gz -C /tmp \
    && cd /tmp/luarocks-3.9.2 \
    && ./configure --prefix=/usr/local/openresty/luajit \
        --with-lua=/usr/local/openresty/luajit \
        --lua-suffix=jit \
        --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 \
    && make -j$(nproc) \
    && make install \
    && rm -rf /tmp/luarocks*

RUN /usr/local/openresty/luajit/bin/luarocks install lpeg \
    && /usr/local/openresty/luajit/bin/luarocks install luasocket \
    && /usr/local/openresty/luajit/bin/luarocks install lua-resty-jit-uuid \
    && /usr/local/openresty/luajit/bin/luarocks install lua-cjson \
    && /usr/local/openresty/luajit/bin/luarocks install lapis \
    && /usr/local/openresty/luajit/bin/luarocks install lua-resty-redis-connector \
    && /usr/local/openresty/luajit/bin/luarocks install lua-resty-mysql \
    && /usr/local/openresty/luajit/bin/luarocks install lua-resty-mlcache

FROM openresty/openresty:1.27.1.1-alpine

COPY --from=builder /usr/local/openresty /usr/local/openresty
COPY --from=builder /app/build_dep.sh /app/build_dep.sh

RUN chmod +x /app/build_dep.sh && sh /app/build_dep.sh && rm -rf /app \
    && apk update \
    && apk add --no-cache bash curl \
    && rm -rf /var/cache/apk/* \
    && addgroup -g 101 -S nginx \
    && adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx \
    && (getent group www-data || addgroup -g 82 -S www-data) \
    && adduser -S -D -H -u 82 -h /var/www -s /usr/sbin/nologin -G www-data -g www-data www-data

ENV PATH="/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin:${PATH}"
ENV LUA_PATH="/usr/local/openresty/lualib/?.lua;/usr/local/openresty/luajit/share/lua/5.1/?.lua;;"
ENV LUA_CPATH="/usr/local/openresty/lualib/?.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so;;"
ENV TZ=Asia/Shanghai

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]