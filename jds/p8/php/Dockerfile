# Description: Dockerfile to install essential PHP dependencies for the environment
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

FROM php:8.0.30-fpm-alpine3.16

RUN set -ex \
        && apk update && apk upgrade \
        && curl -fsL https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions -o /usr/local/bin/install-php-extensions \
        && chmod +x /usr/local/bin/install-php-extensions \
        && /usr/local/bin/install-php-extensions \
            bcmath \
            bz2 \
            calendar \
            exif \
            gd \
            gettext \
            gmp \
            ldap \
            mbstring \
            mysqlnd \
            odbc \
            opcache \
            pdo_mysql \
            soap \
            shmop \
            sysvmsg \
            sysvsem \
            sysvshm \
            xml \
            xmlrpc \
            xsl \
        && rm -f Dockerfile /usr/local/bin/install-php-extensions \
        && rm -rf /var/cache/apk/* /tmp/*