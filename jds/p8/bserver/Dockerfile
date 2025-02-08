# Description: Dockerfile for building the bserver containerized environment
#
# Copyright (C) 2024 - 2025 honeok <honeok@duck.com>
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

RUN set -ex \
        && apk update && apk upgrade \
        && apk add --no-cache libstdc++ libc6-compat tzdata \
        && chmod +x bserver && install -m 755 docker-entrypoint.sh /docker-entrypoint.sh \
        && cp -fv templates/App.json.template config/App.json \
        && cp -fv /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
        && echo "Asia/Shanghai" > /etc/timezone \
        && apk del tzdata \
        && rm -fv Dockerfile docker-entrypoint.sh \
        && rm -rf config/luban_temp \
        && rm -rfv /var/cache/apk/* templates logs BattleSimulator \
        && mkdir -pv logs BattleSimulator config/luban_temp \
        && cp -rfv config/luban/* config/luban_temp/

EXPOSE 8080

ENTRYPOINT [ "/docker-entrypoint.sh" ]