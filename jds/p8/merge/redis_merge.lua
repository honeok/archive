-- redis-cli -h 192.168.0.5 -p 6379 -a 123456 --eval redis_merge.lua
local domain = 'p8_uat'
local dest_id = 1   -- 目标区服id
local merge_id = 2  -- 被合并区服id

-- 秘境探索tower_secret
-- local key = 'api:counter:p8:p8_counter_1_1_1_100'
local counter = string.format("api:counter:%s:%s_counter_1_", domain, domain)
-- api:counter:p8:p8_fc_cross_counter_1_1_1_5
local scan_merge_key = counter .. merge_id .. '_1_*'

local scanKeys = function(scan_key)
    local results = {}
    local cursor = '0'
    repeat
        local result = redis.call('SCAN', cursor, 'MATCH', scan_key)
        cursor = result[1]
        local keys = result[2]
        for _, key in ipairs(keys) do
            local value = redis.call('GET', key)
            table.insert(results, { key = key, value = value })
        end
    until cursor == '0'
    return results
end

local items = scanKeys(scan_merge_key)

local results = {}
for _, item in ipairs(items) do
    local dest_key = string.gsub(item.key, counter .. merge_id, counter .. dest_id)
    local dest_value = redis.call('GET', dest_key) or 0
    local new_value = item.value + dest_value
    if new_value > 0 then
        redis.call('SET', dest_key, new_value)
    end
    table.insert(results, { item.key, item.value, dest_key, dest_value, new_value })
end

return results