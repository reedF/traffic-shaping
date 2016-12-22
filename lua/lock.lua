local lock = require "resty.lock"
local cache = ngx.shared.dict_locks_timer
local key = "lock_key"
for i = 1,2 do
	local val, err = cache:get(key)
	ngx.say("result1: ", val,"<br/>")
    local lock = lock:new("dict_locks_timer")
    local elapsed, err = lock:lock(key,{10})	
    ngx.say("lock: ", elapsed, ", ", err,"<br/>")
	
	val, err = cache:get(key)
	ngx.say("result2: ", val,"<br/>")
	
    local ok, err = lock:unlock()
    if not ok then
       ngx.say("failed to unlock: ", err,"<br/>")
    end
    ngx.say("unlock: ", ok,"<br/>")
	
	val, err = cache:get(key)
	ngx.say("result3: ", val,"<br/>")
end
