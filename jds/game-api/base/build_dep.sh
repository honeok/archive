#!/bin/sh
#
# Description: Configure dependencies for the gameapi Docker image.
#
# Copyright (C) 2025 honeok <honeok@duck.com>
# https://www.honeok.com
# https://github.com/honeok/archive/raw/master/jds/game-api/base/build_dep.sh

geo_check() {
    country=""

    cloudflare_api=$(curl -A "Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/81.0" -m 10 -s "https://dash.cloudflare.com/cdn-cgi/trace" | sed -n 's/.*loc=\([^ ]*\).*/\1/p')
    ipinfo_api=$(curl -fsL --connect-timeout 5 https://ipinfo.io/country)
    ipsb_api=$(curl -fsL --connect-timeout 5 -A Mozilla https://api.ip.sb/geoip | sed -n 's/.*"country_code":"\([^"]*\)".*/\1/p')

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
    if ! command -v curl >/dev/null; then
        apk update && apk add curl
    fi
}

repo_check() {
    geo_check

    if [ ! -f "/etc/apk/repositories" ]; then
        echo "repositories file not found!"
        exit 1
    fi

    if [ "$country" = "CN" ]; then
        sed -i "s|dl-cdn.alpinelinux.org|mirrors.aliyun.com|g" /etc/apk/repositories
    fi
}

cmd_check
repo_check