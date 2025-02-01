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

ARG ROCKY_VERSION=9.3
FROM rockylinux:${ROCKY_VERSION}

WORKDIR /bserver

COPY . .

ENV BSERVER_PORT="8080" TZ=Asia/Shanghai

RUN set -ex \
    && dnf install -y gettext procps \
    && chmod +x bserver && install -m 755 docker-entrypoint.sh /docker-entrypoint.sh \
    && envsubst < App.json.template > config/App.json \
    && rm -f App.json.template Dockerfile \
    && dnf remove -y gettext && dnf clean all && rm -rf /var/cache/dnf/* \
    && rm -rf /opt/config/luban \
    && mkdir -p /opt/config/luban \
    && cp -r config/luban/* /opt/config/luban/ \
    && rm -rfv logs/* BattleSimulator/*

EXPOSE ${BSERVER_PORT}

ENTRYPOINT ["/docker-entrypoint.sh"]