# Description: Dockerfile to install essential PHP dependencies for the environment
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#      __     __       _____
#  __ / / ___/ /  ___ / ___/ ___ _  __ _  ___
# / // / / _  /  (_-</ (_ / / _ `/ /  ' \/ -_)
# \___/  \_,_/  /___/\___/  \_,_/ /_/_/_/\__/
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License, version 3 or later.
#
# This program is distributed WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# See the LICENSE file or <https://www.gnu.org/licenses/> for full license terms.

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