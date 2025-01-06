# Dockerfile from bserver containerization construction
# Copyright (C) 2025 honeok <honeok@duck.com>

ARG ROCKY_VERSION=9.3
FROM rockylinux:${ROCKY_VERSION}

LABEL maintainer="honeok <honeok@duck.com>"

WORKDIR /

COPY . .

RUN chmod +x build_dep.sh && ./build_dep.sh check

ENV SERVER_PORT="8080"
ENV TZ=Asia/Shanghai

RUN envsubst < App.json.template > /bserver/config/App.json && \
    ./build_dep.sh clean && rm -f build_dep.sh

EXPOSE ${SERVER_PORT}

ENTRYPOINT ["entrypoint.sh"]

CMD ["/bserver/bserver"]