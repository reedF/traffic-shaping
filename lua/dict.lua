-- dict refush
-- setting nginx.conf in "http" phase:lua_shared_dict dict_rule_ip 1m;
local cache_ip = ngx.shared.dict_rule_ip
local key = "key"
local v = os.date("%c")
local value, flags = cache_ip:get(key)
ngx.say("Old:" .. tostring(value) .. "<br>") 
local succ, err, forcible = cache_ip:set(key,v) 
if not succ then 
	ngx.log(ngx.ERR,err)
end
value, flags = cache_ip:get(key)
ngx.say("New:" .. value .. "<br>") 


local cache_req = ngx.shared.dict_rule_req
local req_keys = cache_req:get_keys()  
ngx.say(table.getn(req_keys) .. "<br>")
for index, key in pairs(req_keys) do
    str = cache_req:get(key)
    ngx.say("req:" .. key .. "======>" .. tostring(str) .. "======>" .. tostring(cache_req:llen(key)) .. "<br>") 
end

ngx.say("===================<br>") 

local cache_conn = ngx.shared.dict_rule_conn
local conn_keys = cache_conn:get_keys()  
for index, key in pairs(conn_keys) do
    str = cache_conn:get(key)
    ngx.say("conn:" .. key .. "======>" .. tostring(str) .. "<br>") 
end