# Dockerfile from gm-server containerization construction
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# https://www.honeok.com

ARG NODE_VERSION=16.20.2

FROM node:${NODE_VERSION}-alpine

LABEL maintainer="honeok <honeok@duck.com>"

WORKDIR /

COPY . .

RUN chmod +x build_dep.sh && ./build_dep.sh build

CMD ["npm", "--prefix", "gm-server/", "run", "dev"]