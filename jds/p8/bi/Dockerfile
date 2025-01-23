# bi containerized build image Dockerfile
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# https://github.com/honeok/archive/raw/master/jds/bi/Dockerfile
#      __     __       _____                  
#  __ / / ___/ /  ___ / ___/ ___ _  __ _  ___ 
# / // / / _  /  (_-</ (_ / / _ `/ /  ' \/ -_)
# \___/  \_,_/  /___/\___/  \_,_/ /_/_/_/\__/ 
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 or later.
# See <https://www.gnu.org/licenses/>

FROM registry.cn-chengdu.aliyuncs.com/havario/bi-base:2025.01.19-2bc4686

WORKDIR /bi

COPY . .

EXPOSE 8000

ENTRYPOINT ["python3", "server.py"]