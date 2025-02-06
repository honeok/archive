# Description: Dockerfile for building the BI containerized image
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

ARG BUILD_TAG=2025.02.06-slim

FROM registry.cn-chengdu.aliyuncs.com/havario/bi-base:${BUILD_TAG}

WORKDIR /bi

COPY . .

RUN set -ex \
        && apk update && apk upgrade \
        && install -m 755 docker-entrypoint.sh /docker-entrypoint.sh \
        && rm -fv logs/* docker-entrypoint.sh Dockerfile \
        && rm -rfv migrations/models

EXPOSE 8000

ENTRYPOINT [ "/docker-entrypoint.sh" ]