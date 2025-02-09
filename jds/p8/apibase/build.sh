#!/bin/sh

apk add --no-cache \
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
        gd \
        geoip \
        libgcc \
        libxslt \
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
            enable-camellia enable-seed enable-rfc3779 enable-cms enable-md2 enable-rc5 \
            enable-weak-ssl-ciphers enable-ssl3 enable-ssl3-method enable-md2 enable-ktls enable-fips \
    && make -j2 \
    && make -j2 install_sw \
    && cd /tmp \
    && curl -fSL "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.44/pcre2-10.44.tar.gz" -o pcre2-10.44.tar.gz \
    && tar xzf pcre2-10.44.tar.gz \
    && cd pcre2-10.44 \
    && CFLAGS="-g -O3" ./configure \
        --prefix=/usr/local/openresty/pcre2 \
        --libdir=/usr/local/openresty/pcre2/lib \
        --enable-jit --enable-pcre2grep-jit --disable-bsr-anycrlf --disable-coverage --disable-ebcdic --disable-fuzz-support \
        --disable-jit-sealloc --disable-never-backslash-C --enable-newline-is-lf --enable-pcre2-8 --enable-pcre2-16 --enable-pcre2-32 \
        --enable-pcre2grep-callout --enable-pcre2grep-callout-fork --disable-pcre2grep-libbz2 --disable-pcre2grep-libz --disable-pcre2test-libedit \
        --enable-percent-zt --disable-rebuild-chartables --enable-shared --disable-static --disable-silent-rules --enable-unicode --disable-valgrind \
    && CFLAGS="-g -O3" make -j2 \
    && CFLAGS="-g -O3" make -j2 install \
    && cd /tmp \
    && curl -fSL https://openresty.org/download/openresty-1.27.1.1.tar.gz -o openresty-1.27.1.1.tar.gz \
    && tar xzf openresty-1.27.1.1.tar.gz \
    && cd openresty-1.27.1.1 \
    && eval ./configure -j2 --with-pcre \
        --with-cc-opt='-DNGX_LUA_ABORT_AT_PANIC -I/usr/local/openresty/pcre2/include -I/usr/local/openresty/openssl3/include' \
        --with-ld-opt='-L/usr/local/openresty/pcre2/lib -L/usr/local/openresty/openssl3/lib -Wl,-rpath,/usr/local/openresty/pcre2/lib:/usr/local/openresty/openssl3/lib' \
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
        --with-luajit-xcflags='-DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT' \
        --with-pcre-jit \
    && make -j2 \
    && make -j2 install \
    && cd /tmp \
    && curl -fsL -O https://luarocks.github.io/luarocks/releases/luarocks-3.9.2.tar.gz \
    && tar zxpf luarocks-3.9.2.tar.gz \
    && cd luarocks-3.9.2 \
    && ./configure --prefix=/usr/local/openresty/luajit --with-lua=/usr/local/openresty/luajit --lua-suffix=jit --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 \
    && make -j2 \
    && make -j2 install \
    && cd / \
    && /usr/local/openresty/luajit/bin/luarocks install lpeg \
    && /usr/local/openresty/luajit/bin/luarocks install luasocket \
    && /usr/local/openresty/luajit/bin/luarocks install lua-resty-jit-uuid \
    && /usr/local/openresty/luajit/bin/luarocks install lua-cjson \
    && /usr/local/openresty/luajit/bin/luarocks install lapis \
    && /usr/local/openresty/luajit/bin/luarocks install lua-resty-redis-connector \
    && /usr/local/openresty/luajit/bin/luarocks install lua-resty-mysql \
    && /usr/local/openresty/luajit/bin/luarocks install lua-resty-mlcache \
    && cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && rm -rf /tmp/* \
    && apk del .build-deps \
    && rm -rf /var/cache/apk/* \
    && mkdir -p /var/run/openresty /var/cache/nginx \
    && addgroup -g 101 -S nginx \
    && adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx \
    && chown nginx:nginx /var/cache/nginx \
    && chown -R nginx:nginx /usr/local/openresty /etc/nginx /var/run/openresty
    # && ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log \
    # && ln -sf /dev/stderr /usr/local/openresty/nginx/logs/error.log