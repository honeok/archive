#!/usr/bin/env bash
#
# Description: Automates the backup process for production environment MySQL databases.
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

set \
    -o errexit \
    -o nounset

readonly version='v0.2.1 (2025.03.19)'

