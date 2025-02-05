# Description: Dockerfile to install essential PHP dependencies for the environment
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

FROM php:8.0.30-fpm-alpine3.16

RUN set -ex \
        && apk update \
        && curl -fsL https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions -o /usr/local/bin/install-php-extensions \
        && chmod +x /usr/local/bin/install-php-extensions \
        && /usr/local/bin/install-php-extensions opcache mysqlnd pdo_mysql gd ldap odbc xml xmlrpc mbstring soap gmp bcmath bcmath bz2  \
            calendar exif gettext shmop sysvmsg sysvsem sysvshm xmlrpc xsl \
        && rm -fv Dockerfile /usr/local/bin/install-php-extensions \
        && rm -rfv /var/cache/apk/*