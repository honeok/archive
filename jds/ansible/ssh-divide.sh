#!/usr/bin/env bash
#
# Description: Automates the distribution of SSH keys across multiple hosts using Ansible for password-less SSH login.
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# https://www.honeok.com
# https://github.com/honeok/archive/raw/master/jds/ansible/ssh-divide.sh
#      __     __       _____                  
#  __ / / ___/ /  ___ / ___/ ___ _  __ _  ___ 
# / // / / _  /  (_-</ (_ / / _ `/ /  ' \/ -_)
# \___/  \_,_/  /___/\___/  \_,_/ /_/_/_/\__/ 
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 or later.
# See <https://www.gnu.org/licenses/>

set \
    -o errexit \
    -o nounset

control_hosts=( 192.168.100.10 192.168.100.20 )
key_path="$HOME/.ssh/id_rsa"

if [ ! -f "$key_path" ]; then
    expect <<EOF
spawn ssh-keygen -t rsa -b 4096 -f $key_path
expect "Enter file in which to save the key" { send "\r" }
expect "Enter passphrase (empty for no passphrase)" { send "\r" }
expect "Enter same passphrase again" { send "\r" }
expect eof
EOF
fi

for host in "${control_hosts[@]}"; do
    if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" exit >/dev/null 2>&1; then
        ssh-copy-id -i "$key_path.pub" "$host"
    fi
done