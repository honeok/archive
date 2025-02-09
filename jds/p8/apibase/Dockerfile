# Description: Dockerfile for the gameapi basic environment based on Alpine
#
# Copyright (C) 2025 honeok <honeok@duck.com>
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

# Docker Build Arguments
ARG RESTY_IMAGE_BASE="alpine"
ARG RESTY_IMAGE_TAG="3.21"

FROM ${RESTY_IMAGE_BASE}:${RESTY_IMAGE_TAG}

ARG RESTY_VERSION="1.27.1.1"

# https://github.com/openresty/openresty-packaging/blob/master/alpine/openresty-openssl3/APKBUILD
# LEGACY:  "https://www.openssl.org/source/old/1.1.1"
ARG RESTY_OPENSSL_BUILD_OPTIONS="enable-camellia enable-seed enable-rfc3779 enable-cms enable-md2 enable-rc5 \
        enable-weak-ssl-ciphers enable-ssl3 enable-ssl3-method enable-md2 enable-ktls enable-fips \
        "

# https://github.com/openresty/openresty-packaging/blob/master/alpine/openresty-pcre2/APKBUILD
ARG RESTY_PCRE_BUILD_OPTIONS="--enable-jit --enable-pcre2grep-jit --disable-bsr-anycrlf --disable-coverage --disable-ebcdic --disable-fuzz-support \
    --disable-jit-sealloc --disable-never-backslash-C --enable-newline-is-lf --enable-pcre2-8 --enable-pcre2-16 --enable-pcre2-32 \
    --enable-pcre2grep-callout --enable-pcre2grep-callout-fork --disable-pcre2grep-libbz2 --disable-pcre2grep-libz --disable-pcre2test-libedit \
    --enable-percent-zt --disable-rebuild-chartables --enable-shared --disable-static --disable-silent-rules --enable-unicode --disable-valgrind \
    "

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

RUN set -ex \
        && apk update && apk upgrade \
        && apk add --no-cache --virtual .build-deps \
            build-base \
            coreutils \
            curl \
            gd-dev \
            geoip-dev \
            libxslt-dev \
            linux-headers \
            make \
            perl-dev \
            readline-dev \
            zlib-dev \
        && apk add --no-cache \
            gd \
            geoip \
            libgcc \
            libxslt \
            tzdata \
            zlib \
        && cd /tmp \
        && curl -fSL "https://github.com/openssl/openssl/releases/download/openssl-3.0.15/openssl-3.0.15.tar.gz" -o openssl-3.0.15.tar.gz \
        && tar xzf openssl-3.0.15.tar.gz \
        && cd openssl-3.0.15 \
        && curl -s https://raw.githubusercontent.com/openresty/openresty/master/patches/openssl-3.0.15-sess_set_get_cb_yield.patch | patch -p1 \
        && ./config \
                shared zlib -g \
                --prefix=/usr/local/openresty/openssl3 \
                --libdir=lib \
                -Wl,-rpath,/usr/local/openresty/openssl3/lib \
                ${RESTY_OPENSSL_BUILD_OPTIONS} \
        && make -j$(nproc) \
        && make -j$(nproc) install_sw \
        && cd /tmp \
        && curl -fSL "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.44/pcre2-10.44.tar.gz" -o pcre2-10.44.tar.gz \
        && tar xzf pcre2-10.44.tar.gz \
        && cd /tmp/pcre2-10.44 \
        && CFLAGS="-g -O3" ./configure \
            --prefix=/usr/local/openresty/pcre2 \
            --libdir=/usr/local/openresty/pcre2/lib \
            ${RESTY_PCRE_BUILD_OPTIONS} \
        && CFLAGS="-g -O3" make -j$(nproc) \
        && CFLAGS="-g -O3" make -j$(nproc) install \
        && cd /tmp \
        && curl -fSL https://openresty.org/download/openresty-${RESTY_VERSION}.tar.gz -o openresty-${RESTY_VERSION}.tar.gz \
        && tar xzf openresty-${RESTY_VERSION}.tar.gz \
        && cd /tmp/openresty-${RESTY_VERSION} \
        && eval ./configure -j$(nproc) ${_RESTY_CONFIG_DEPS} ${RESTY_CONFIG_OPTIONS} ${RESTY_LUAJIT_OPTIONS} ${RESTY_PCRE_OPTIONS} \
        && make -j$(nproc) \
        && make -j$(nproc) install \
        && cd /tmp \
        && rm -rfv \
            openssl-3.0.15.tar.gz openssl-3.0.15 \
            pcre2-10.44.tar.gz pcre2-10.44 \
            openresty-${RESTY_VERSION}.tar.gz openresty-${RESTY_VERSION} \
        && apk del .build-deps \
        && mkdir -p /var/run/openresty \
        && ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log \
        && ln -sf /dev/stderr /usr/local/openresty/nginx/logs/error.log

# Add additional binaries into PATH for convenience
ENV PATH=$PATH:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin

# Copy nginx configuration files
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY nginx.vh.default.conf /etc/nginx/conf.d/default.conf

CMD [ "/usr/local/openresty/bin/openresty", "-g", "daemon off;" ]

# Use SIGQUIT instead of default SIGTERM to cleanly drain requests
# See https://github.com/openresty/docker-openresty/blob/master/README.md#tips--pitfalls
STOPSIGNAL SIGQUIT