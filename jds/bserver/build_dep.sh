#!/bin/sh
#
# Description: Configure dependencies for the bserver Docker image.
# System Required: rocky8+
#
# Copyright (C) 2025 honeok <honeok@duck.com>
# https://www.honeok.com
# https://github.com/honeok/archive/raw/master/jds/bserver/build_dep.sh

set \
    -o errexit \
    -o nounset \
    -o xtrace

os_name=$(grep ^ID= /etc/*release | awk -F'=' '{print $2}' | sed 's/"//g')
[ "$os_name" != "rocky" ] && echo "This script is only for rockylinux." && exit 1

if ! command -v curl >/dev/null 2>&1; then
    dnf -y install curl
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

repo_check() {
    if ! find /etc/yum.repos.d/ -type f -name "[Rr]ocky*.repo" >/dev/null 2>&1; then
        echo "repo file not found!" && exit 1
    fi

    if [ "$country" = "CN" ]; then
        #s#old#new#g
        sed -e "s|^mirrorlist=|#mirrorlist=|g" \
            -e "s|^#baseurl=http://dl.rockylinux.org/\$contentdir|baseurl=https://mirrors.aliyun.com/rockylinux|g" \
            -i.bak \
            /etc/yum.repos.d/[Rr]ocky*.repo
    fi
}

cmd_check() {
    commands="gettext procps"

    dnf -y update

    for cmd in $commands; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            dnf -y install "$cmd"
        fi
    done
}

run_check() {
    if [ ! -x "/bserver/bserver" ]; then
        chmod +x /bserver/bserver
    fi
}

last_clean() {
    if [ -e "App.json.template" ]; then
        rm -f App.json.template
    fi

    if [ -e "Dockerfile" ]; then
        rm -f Dockerfile
    fi

    if command -v gettext >/dev/null 2>&1; then
        dnf remove -y gettext
    fi
    dnf clean all && rm -rf /var/cache/dnf/*
}

case "$1" in
    build)
        geo_check
        repo_check
        cmd_check
        run_check
        ;;
    clean)
        last_clean
        ;;
    *)
        echo "Usage: $0 {build|clean}"
        exit 1
        ;;
esac