-- utf-8

-- 域
domain = "${DOMAIN}"
-- 本地地址
ip = "${LOCAL_ADDRESS}"
-- 端口
port = 3340
-- 地址
server = string.format("tcp://0.0.0.0:%d", port)
-- 互联互通
cluster = string.format("tcp://%s:%d", ip, port)
-- 线程数
thread = 8
-- 日志配置
logger = "etc/server.log.ini"
-- 时间偏移量
time_offset = 0
-- 时区
time_zone = 8

-- 服务发现
discovers = {
    "tcp://${DISCOVER_NODE1}",
    "tcp://${DISCOVER_NODE2}",
    "tcp://${DISCOVER_NODE3}",
}

game_db = {
    ["host"] = "${GAMEDB_HOST}",
    ["user"] = "${GAMEDB_USER}",
    ["password"] = "${GAMEDB_PASSWORD}",
    ["name"] = "${GAMEDB_DATABASE}",
}

-- 组编号
group_id = "${GROUP_ID}"
-- 区域编号
area_id = "${AREA_ID}"

-- 游戏服务
game_index_num = 2
-- kingnet回调地址
pay_notify_url = "${PAY_NOTIFY}"

require("etc/services")
require("etc/zones")
require("etc/server")