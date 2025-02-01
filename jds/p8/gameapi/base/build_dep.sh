#!/bin/sh
#
# Description: Configure dependencies for the gameapi Docker image on Alpine Linux.
# System Required: Alpine 3.19 or higher.
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# https://github.com/honeok/archive/raw/master/jds/p8/game-api/base/build_dep.sh
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

set \
    -o errexit \
    -o nounset \
    -o pipefail \
    -o xtrace

os_name=$(grep ^ID= /etc/*release | awk -F'=' '{print $2}' | sed 's/"//g')
[ "$os_name" != "alpine" ] && echo "This script is only for Alpine Linux." && exit 1

cmd_check() {
    if ! command -v curl >/dev/null 2>&1; then
        apk update && apk add curl
    fi
}

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
    if [ ! -f "/etc/apk/repositories" ]; then
        echo "repositories file not found!" && exit 1
    fi

    if [ "$country" = "CN" ]; then
        # s#old#new#g
        sed -i "s#dl-cdn.alpinelinux.org#mirrors.aliyun.com#g" /etc/apk/repositories
    fi
}

cmd_check
geo_check
repo_check