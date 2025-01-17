#!/usr/bin/env bash

cd /data/dbback/
find /data/dbback/ -mtime +3 -name "*.sql" | xargs rm -rf

/usr/bin/mysqldump --no-defaults --single-transaction --set-gtid-purged=OFF -h 10.46.96.179 -P 3306 -u root -pxxxxxxxxxxx -R cbt4_game_1 > /data/dbback/cbt4_game_1_$(date +%Y%m%d%H%M%S).sql
/usr/bin/mysqldump --no-defaults --single-transaction --set-gtid-purged=OFF -h 10.46.96.179 -P 3306 -u root -pxxxxxxxxxxx -R cbt4_game_2 > /data/dbback/cbt4_game_2_$(date +%Y%m%d%H%M%S).sql
/usr/bin/mysqldump --no-defaults --single-transaction --set-gtid-purged=OFF -h 10.46.96.179 -P 3306 -u root -pxxxxxxxxxxx -R cbt4_game_3 > /data/dbback/cbt4_game_3_$(date +%Y%m%d%H%M%S).sql
/usr/bin/mysqldump --no-defaults --single-transaction --set-gtid-purged=OFF -h 10.46.96.179 -P 3306 -u root -pxxxxxxxxxxx -R cbt4_game_4 > /data/dbback/cbt4_game_4_$(date +%Y%m%d%H%M%S).sql
/usr/bin/mysqldump --no-defaults --single-transaction --set-gtid-purged=OFF -h 10.46.96.179 -P 3306 -u root -pxxxxxxxxxxx -R cbt4_game_5 > /data/dbback/cbt4_game_5_$(date +%Y%m%d%H%M%S).sql

/usr/bin/mysqldump --no-defaults --single-transaction --set-gtid-purged=OFF -h 10.46.96.179 -P 3306 -u root -pxxxxxxxxxxx -R cbt4_common > /data/dbback/cbt4_common_$(date +%Y%m%d%H%M%S).sql

/usr/bin/mysqldump --no-defaults --single-transaction --set-gtid-purged=OFF -h 10.46.96.179 -P 3306 -u root -pxxxxxxxxxxx -R cbt4_account > /data/dbback/cbt4_account_$(date +%Y%m%d%H%M%S).sql

/usr/bin/mysqldump --no-defaults --single-transaction --set-gtid-purged=OFF -h 10.46.96.179 -P 3306 -u root -pxxxxxxxxxxx -R cbt4_center > /data/dbback/cbt4_center_$(date +%Y%m%d%H%M%S).sql

#/usr/bin/mysqldump --no-defaults --single-transaction --set-gtid-purged=OFF -h 10.46.96.179 -P 3306 -u root -pxxxxxxxxxxx -R cbt4_log > /data/dbback/cbt4_log_$(date +%Y%m%d%H%M%S).sql

/usr/bin/mysqldump --no-defaults --single-transaction --set-gtid-purged=OFF -h 10.46.96.179 -P 3306 -u root -pxxxxxxxxxxx -R cbt4_report > /data/dbback/cbt4_report_$(date +%Y%m%d%H%M%S).sql

/usr/bin/mysqldump --no-defaults --single-transaction --set-gtid-purged=OFF -h 10.46.96.179 -P 3306 -u root -pxxxxxxxxxxx -R cbt4_gm > /data/dbback/cbt4_gm_$(date +%Y%m%d%H%M%S).sql