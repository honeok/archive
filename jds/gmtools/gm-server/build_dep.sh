#!/bin/sh
#
# Description: Configure dependencies for the gm-server Docker image.
# System Required: rocky8+
#
# Copyright (C) 2025 honeok <honeok@duck.com>
# https://www.honeok.com
# https://github.com/honeok/archive/raw/master/jds/gmtools/gm-server/build_dep.sh

set \
    -o errexit \
    -o nounset \
    -o xtrace

os_name=$(grep ^ID= /etc/*-release | awk -F'=' '{print $2}' | sed 's/"//g')
[ "$os_name" != "alpine" ] && echo "This script is only for Alpine Linux." && exit 1

if ! command -v curl >/dev/null 2>&1; then
    apk add --no-cache curl
fi

geo_check() {
    country=""

    cloudflare_api=$(curl -sL -m 10 -A "Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/81.0" "https://dash.cloudflare.com/cdn-cgi/trace" | sed -n 's/.*loc=\([^ ]*\).*/\1/p')
    ipinfo_api=$(curl -sL --connect-timeout 5 https://ipinfo.io/country)
    ipsb_api=$(curl -sL --connect-timeout 5 -A Mozilla https://api.ip.sb/geoip | sed -n 's/.*"country_code":"\([^"]*\)".*/\1/p')

    for api in "$cloudflare_api" "$ipinfo_api" "$ipsb_api"; do
        if [ -n "$api" ]; then
            country="$api"
            break
        fi
    done

    if [ -z "$country" ]; then
        echo "Unable to obtain the location of the server, please check the network and try again!" && exit 1
    fi
}

cmd_check() {
    commands="tar wget tzdata ca-certificates"

    apk update

    for cmd in $commands; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            apk add --no-cache "$cmd"
        fi
    done
}

date_check() {
    if [ "$country" = "CN" ]; then
        ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
        echo "Asia/Shanghai" > /etc/timezone
    fi
}

repo_check() {
    if [ ! -f "/etc/apk/repositories" ]; then
        echo "repositories file not found!" && exit 1
    fi

    if [ "$country" = "CN" ]; then
        #s#old#new#g
        sed -i "s@dl-cdn.alpinelinux.org@mirrors.aliyun.com@g" /etc/apk/repositories
        npm config set registry https://r.cnpmjs.org
    fi
}

pre_check() {
    if [ -d "gm-server" ]; then
        cd gm-server || exit 1
    fi
    if [ ! -d "node_modules" ]; then
        npm install
    fi
}

case "$1" in
    build)
        geo_check
        cmd_check
        date_check
        repo_check
        pre_check
        ;;
    *)
        echo "Usage: $0 build"
        exit 1
        ;;
esac
