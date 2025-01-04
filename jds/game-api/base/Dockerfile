# Dockerfile from gameapi basic environment based on alpine
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# Reference:
# https://github.com/luarocks/luarocks/wiki/Download
# https://github.com/nginxinc/docker-nginx/blob/master/mainline/alpine-slim/Dockerfile

FROM openresty/openresty:1.27.1.1-alpine AS build

LABEL maintainer="honeok <honeok@duck.com>"

WORKDIR /app

COPY . .

RUN apk update && \
    chmod +x build_dep.sh && sh build_dep.sh && \
    apk add --no-cache gcc g++ make pcre-dev zlib-dev openssl-dev wget bash tar git libtool automake && \
    rm -rf /var/cache/apk/*

RUN curl -L https://luarocks.org/releases/luarocks-3.9.2.tar.gz -o /tmp/luarocks-3.9.2.tar.gz && \
    tar zxpf /tmp/luarocks-3.9.2.tar.gz -C /tmp && \
    cd /tmp/luarocks-3.9.2 && \
    ./configure --prefix=/usr/local/openresty/luajit \
        --with-lua=/usr/local/openresty/luajit \
        --lua-suffix=jit \
        --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 && \
    make && make install && \
    rm -rf /tmp/luarocks*

RUN /usr/local/openresty/luajit/bin/luarocks install lpeg && \
    /usr/local/openresty/luajit/bin/luarocks install luasocket && \
    /usr/local/openresty/luajit/bin/luarocks install lua-resty-jit-uuid && \
    /usr/local/openresty/luajit/bin/luarocks install lua-cjson && \
    /usr/local/openresty/luajit/bin/luarocks install lapis && \
    /usr/local/openresty/luajit/bin/luarocks install lua-resty-redis-connector && \
    /usr/local/openresty/luajit/bin/luarocks install lua-resty-mysql && \
    /usr/local/openresty/luajit/bin/luarocks install lua-resty-mlcache

FROM openresty/openresty:1.27.1.1-alpine

LABEL maintainer="honeok <honeok@duck.com>"

COPY --from=build /usr/local/openresty /usr/local/openresty
COPY --from=build /etc/apk/keys /etc/apk/keys
COPY --from=build /app/build_dep.sh /app/build_dep.sh

RUN chmod +x /app/build_dep.sh && sh /app/build_dep.sh && rm -rf /app && \
    apk update && \
    apk add --no-cache bash curl && \
    rm -rf /var/cache/apk/* && \
    addgroup -g 101 -S nginx && \
    adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx && \
    addgroup -g 33 -S www-data && \
    adduser -S -D -H -u 33 -h /var/www -s /usr/sbin/nologin -G www-data -g www-data www-data

ENV PATH="/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin:${PATH}"
ENV LUA_PATH="/usr/local/openresty/lualib/?.lua;/usr/local/openresty/luajit/share/lua/5.1/?.lua;;"
ENV LUA_CPATH="/usr/local/openresty/lualib/?.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so;;"
ENV TZ=Asia/Shanghai

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]