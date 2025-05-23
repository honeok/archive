# Description: Dockerfile for the gameapi basic environment based on Alpine
#
# Copyright (c) 2025 honeok <honeok@duck.com>
#
# References:
# https://github.com/luarocks/luarocks/wiki/Download
# https://github.com/openresty/docker-openresty/blob/master/alpine/Dockerfile
# https://github.com/nginxinc/docker-nginx/blob/master/mainline/alpine-slim/Dockerfile
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

ARG RESTY_IMAGE_BASE="alpine"
ARG RESTY_IMAGE_TAG="3.21"

FROM ${RESTY_IMAGE_BASE}:${RESTY_IMAGE_TAG}

# Docker Build Arguments
ARG RESTY_VERSION="1.27.1.1"

# https://github.com/openresty/openresty-packaging/blob/master/alpine/openresty-openssl3/APKBUILD
ARG RESTY_OPENSSL_VERSION="3.0.15"
ARG RESTY_OPENSSL_PATCH_VERSION="3.0.15"
ARG RESTY_OPENSSL_URL_BASE="https://github.com/openssl/openssl/releases/download/openssl-${RESTY_OPENSSL_VERSION}"
# LEGACY:  "https://www.openssl.org/source/old/1.1.1"
ARG RESTY_OPENSSL_BUILD_OPTIONS="enable-camellia enable-seed enable-rfc3779 enable-cms enable-md2 enable-rc5 \
        enable-weak-ssl-ciphers enable-ssl3 enable-ssl3-method enable-md2 enable-ktls enable-fips \
        "

# https://github.com/openresty/openresty-packaging/blob/master/alpine/openresty-pcre2/APKBUILD
ARG RESTY_PCRE_VERSION="10.44"
ARG RESTY_PCRE_BUILD_OPTIONS="--enable-jit --enable-pcre2grep-jit --disable-bsr-anycrlf --disable-coverage --disable-ebcdic --disable-fuzz-support \
    --disable-jit-sealloc --disable-never-backslash-C --enable-newline-is-lf --enable-pcre2-8 --enable-pcre2-16 --enable-pcre2-32 \
    --enable-pcre2grep-callout --enable-pcre2grep-callout-fork --disable-pcre2grep-libbz2 --disable-pcre2grep-libz --disable-pcre2test-libedit \
    --enable-percent-zt --disable-rebuild-chartables --enable-shared --disable-static --disable-silent-rules --enable-unicode --disable-valgrind \
    "

ARG RESTY_J="4"

# https://github.com/openresty/openresty-packaging/blob/master/alpine/openresty/APKBUILD
ARG RESTY_CONFIG_OPTIONS="\
    --with-compat \
    --without-http_rds_json_module \
    --without-http_rds_csv_module \
    --without-lua_rds_parser \
    --without-mail_pop3_module \
    --without-mail_imap_module \
    --without-mail_smtp_module \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_geoip_module=dynamic \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_image_filter_module=dynamic \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-http_v3_module \
    --with-http_xslt_module=dynamic \
    --with-ipv6 \
    --with-mail \
    --with-mail_ssl_module \
    --with-md5-asm \
    --with-sha1-asm \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-threads \
    "

ARG RESTY_LUAJIT_OPTIONS="--with-luajit-xcflags='-DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT'"
ARG RESTY_PCRE_OPTIONS="--with-pcre-jit"

# These are not intended to be user-specified
ARG _RESTY_CONFIG_DEPS="--with-pcre \
    --with-cc-opt='-DNGX_LUA_ABORT_AT_PANIC -I/usr/local/openresty/pcre2/include -I/usr/local/openresty/openssl3/include' \
    --with-ld-opt='-L/usr/local/openresty/pcre2/lib -L/usr/local/openresty/openssl3/lib -Wl,-rpath,/usr/local/openresty/pcre2/lib:/usr/local/openresty/openssl3/lib' \
    "

ARG RESTY_LUAROCKS_VERSION="3.9.2"
ARG RESTY_LUAROCKS_BUILD_OPTIONS="--lua-suffix=jit --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1"

RUN set -ex \
        && apk update && apk upgrade \
        && apk add --no-cache --virtual .build-deps \
            build-base \
            coreutils \
            curl \
            wget \
            git \
            gd-dev \
            geoip-dev \
            libtool \
            libxslt-dev \
            linux-headers \
            make \
            automake \
            pcre-dev \
            perl-dev \
            readline-dev \
            zlib-dev \
            openssl-dev \
            tzdata \
        && apk add --no-cache \
            gd \
            geoip \
            libgcc \
            libxslt \
            mysql-dev \
            zlib \
        && cd /tmp \
        && curl -fsL "${RESTY_OPENSSL_URL_BASE}/openssl-${RESTY_OPENSSL_VERSION}.tar.gz" -o openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
        && tar xzf openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
        && cd openssl-${RESTY_OPENSSL_VERSION} \
        && curl -fsL https://raw.githubusercontent.com/openresty/openresty/master/patches/openssl-${RESTY_OPENSSL_PATCH_VERSION}-sess_set_get_cb_yield.patch | patch -p1 \
        && ./config \
                shared zlib -g \
                --prefix=/usr/local/openresty/openssl3 \
                --libdir=lib \
                -Wl,-rpath,/usr/local/openresty/openssl3/lib \
                ${RESTY_OPENSSL_BUILD_OPTIONS} \
        && make -j${RESTY_J} \
        && make -j${RESTY_J} install_sw \
        && cd /tmp \
        && curl -fsL "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${RESTY_PCRE_VERSION}/pcre2-${RESTY_PCRE_VERSION}.tar.gz" -o pcre2-${RESTY_PCRE_VERSION}.tar.gz \
        && tar xzf pcre2-${RESTY_PCRE_VERSION}.tar.gz \
        && cd pcre2-${RESTY_PCRE_VERSION} \
        && CFLAGS="-g -O3" ./configure \
            --prefix=/usr/local/openresty/pcre2 \
            --libdir=/usr/local/openresty/pcre2/lib \
            ${RESTY_PCRE_BUILD_OPTIONS} \
        && CFLAGS="-g -O3" make -j${RESTY_J} \
        && CFLAGS="-g -O3" make -j${RESTY_J} install \
        && cd /tmp \
        && curl -fsL "https://openresty.org/download/openresty-${RESTY_VERSION}.tar.gz" -o openresty-${RESTY_VERSION}.tar.gz \
        && tar xzf openresty-${RESTY_VERSION}.tar.gz \
        && cd openresty-${RESTY_VERSION} \
        && eval ./configure -j${RESTY_J} ${_RESTY_CONFIG_DEPS} ${RESTY_CONFIG_OPTIONS} ${RESTY_LUAJIT_OPTIONS} ${RESTY_PCRE_OPTIONS} \
        && make -j${RESTY_J} \
        && make -j${RESTY_J} install \
        && cd /tmp \
        && curl -fsL "https://luarocks.github.io/luarocks/releases/luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz" -o luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
        && tar zxpf luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
        && cd luarocks-${RESTY_LUAROCKS_VERSION} \
        && ./configure \
            --prefix=/usr/local/openresty/luajit \
            --with-lua=/usr/local/openresty/luajit \
            ${RESTY_LUAROCKS_BUILD_OPTIONS} \
        && make -j${RESTY_J} \
        && make -j${RESTY_J} install \
        && cd / \
        && /usr/local/openresty/luajit/bin/luarocks install ansicolors \
        && /usr/local/openresty/luajit/bin/luarocks install argparse \
        && /usr/local/openresty/luajit/bin/luarocks install date \
        && /usr/local/openresty/luajit/bin/luarocks install etlua \
        && /usr/local/openresty/luajit/bin/luarocks install lapis \
        && /usr/local/openresty/luajit/bin/luarocks install loadkit \
        && /usr/local/openresty/luajit/bin/luarocks install lpeg \
        && /usr/local/openresty/luajit/bin/luarocks install lua-cjson \
        && /usr/local/openresty/luajit/bin/luarocks install lua-resty-hmac-ffi \
        && /usr/local/openresty/luajit/bin/luarocks install lua-resty-http \
        && /usr/local/openresty/luajit/bin/luarocks install lua-resty-mlcache \
        && /usr/local/openresty/luajit/bin/luarocks install lua-resty-openssl \
        && /usr/local/openresty/luajit/bin/luarocks install lua-resty-redis \
        && /usr/local/openresty/luajit/bin/luarocks install lua-resty-requests \
        && /usr/local/openresty/luajit/bin/luarocks install luaossl \
        && /usr/local/openresty/luajit/bin/luarocks install luasocket \
        && /usr/local/openresty/luajit/bin/luarocks install luasql-mysql MYSQL_INCDIR=/usr/include/mysql \
        && /usr/local/openresty/luajit/bin/luarocks install net-url \
        && /usr/local/openresty/luajit/bin/luarocks install pgmoon \
        && cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
        && echo "Asia/Shanghai" > /etc/timezone \
        && mkdir -p /var/run/openresty /var/cache/nginx /etc/nginx/conf.d \
        && curl -fsL https://raw.githubusercontent.com/openresty/docker-openresty/master/nginx.vh.default.conf -o /etc/nginx/conf.d/default.conf \
        && curl -fsL https://raw.githubusercontent.com/openresty/docker-openresty/master/nginx.conf -o /usr/local/openresty/nginx/conf/nginx.conf \
        && sed -i 's/^#user  nobody;/user  nginx;/' /usr/local/openresty/nginx/conf/nginx.conf \
        && addgroup -g 1001 -S nginx \
        && adduser -S -D -H -u 1001 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx \
        && chown -R nginx:nginx /usr/local/openresty /var/run/openresty /etc/nginx /var/cache/nginx \
        && rm -rf /var/cache/apk/* /tmp/* \
        && apk del .build-deps \
        && ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log \
        && ln -sf /dev/stderr /usr/local/openresty/nginx/logs/error.log

ENV PATH=$PATH:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin
ENV LUA_PATH=/usr/local/openresty/lualib/?.lua;/usr/local/openresty/luajit/share/lua/5.1/?.lua;;
ENV LUA_CPATH=/usr/local/openresty/lualib/?.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so;;

CMD [ "/usr/local/openresty/bin/openresty", "-g", "daemon off;" ]

# Use SIGQUIT instead of default SIGTERM to cleanly drain requests
# See https://github.com/openresty/docker-openresty/blob/master/README.md#tips--pitfalls
STOPSIGNAL SIGQUIT