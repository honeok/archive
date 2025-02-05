#!/bin/bash

docker exec nginx chown -R nginx:nginx /var/www/html
docker exec php chown -R www-data:www-data /var/www/html
docker compose restart