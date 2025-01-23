FROM php:8.1.30-fpm-alpine3.20

RUN apk update && apk add --no-cache \
    curl \
    && curl -fskL https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions -o /usr/local/bin/install-php-extensions \
    && chmod +x /usr/local/bin/install-php-extensions \
    && /usr/local/bin/install-php-extensions opcache mysqlnd pdo_mysql gd ldap odbc xml xmlrpc mbstring soap gmp bcmath \
        bcmath bz2 calendar exif gettext shmop sysvmsg sysvsem sysvshm xmlrpc xsl \
    && rm -rf /var/cache/apk/*