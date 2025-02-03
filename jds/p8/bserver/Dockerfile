# Description: Dockerfile for building the bserver containerized environment
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

FROM alpine:latest

WORKDIR /bserver

COPY . .

ENV BSERVER_PORT="8080" TZ=Asia/Shanghai

RUN set -ex \
    && apk update && apk add --no-cache libc6-compat libgcc libstdc++ g++ gettext procps \
    && chmod +x bserver && install -m 755 docker-entrypoint.sh /docker-entrypoint.sh \
    && envsubst < App.json.template > config/App.json \
    && apk del gettext \
    && rm -f App.json.template Dockerfile \
    && rm -rf config/luban_temp \
    && rm -rfv /var/cache/apk/* logs/* BattleSimulator/* \
    && mkdir -p config/luban_temp \
    && cp -rfv config/luban/* config/luban_temp/

EXPOSE ${BSERVER_PORT}

ENTRYPOINT [ "/docker-entrypoint.sh" ]