# Dockerfile from bserver containerization construction
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# https://www.honeok.com

ARG ROCKY_VERSION=9.3

FROM rockylinux:${ROCKY_VERSION}

LABEL maintainer="honeok <honeok@duck.com>"

WORKDIR /

COPY . .

RUN chmod +x build_dep.sh && ./build_dep.sh build

ENV SERVER_PORT="8080"
ENV TZ=Asia/Shanghai

RUN ./build_dep.sh genconf && \
    ./build_dep.sh clean && rm -f build_dep.sh

EXPOSE ${SERVER_PORT}

ENTRYPOINT ["entrypoint.sh"]

CMD ["/bserver/bserver"]