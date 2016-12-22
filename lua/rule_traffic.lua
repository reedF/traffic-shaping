-- setting nginx.conf in http phase:
-- 	lua_shared_dict dict_rule_conn 10m;
--	lua_shared_dict dict_rule_req 10m;
-- setting in location phase:
-- access_by_lua_block {
--			require("lua.rule_traffic").check_traffic()
--		  }
-- log_by_lua_block {
--			require("lua.rule_traffic").logger()
--		  }

local limit_conn = require "resty.limit.conn"
local limit_req = require "resty.limit.req"
local limit_traffic = require "resty.limit.traffic"

local _M = {
    _VERSION = '1.0',
}

local mt = { __index = _M }
function _M.check_traffic()
	local lim1, err = limit_req.new("dict_rule_req", 300, 200)
	assert(lim1, err)
	local lim2, err = limit_req.new("dict_rule_req", 200, 100)
	assert(lim2, err)
	local lim3, err = limit_conn.new("dict_rule_conn", 10000, 1000, 0.5)
	assert(lim3, err)

	local limiters = {lim1, lim2, lim3}

	local host = ngx.var.host
	--local client = ngx.var.binary_remote_addr
	local client = ngx.var.remote_addr
	local keys = {host, client, host}

	local states = {}

	local delay, err = limit_traffic.combine(limiters, keys, states)
	ngx.log(ngx.INFO,"============>" .. tostring(delay) .. "===" .. tostring(err))
	if not delay then
		if err == "rejected" then
			return ngx.exit(503)
		end
	ngx.log(ngx.ERR, "failed to limit traffic: ", err)
	return ngx.exit(500)
	end

	if lim3:is_committed() then
		local ctx = ngx.ctx
		ctx.limit_conn = lim3
		ctx.limit_conn_key = keys[3]
	end

	print("sleeping ", delay, " sec, states: ", table.concat(states, ", "))

	if delay >= 0.001 then
		ngx.sleep(delay)
	end

end
function _M.logger() 
	local ctx = ngx.ctx
	local lim = ctx.limit_conn
	if lim then
		-- if you are using an upstream module in the content phase,
		-- then you probably want to use $upstream_response_time
		-- instead of $request_time below.
		local latency = tonumber(ngx.var.request_time)
		local key = ctx.limit_conn_key		
		assert(key)
		local conn, err = lim:leaving(key, latency)
		ngx.log(ngx.INFO, "===========>" .. key .. "==" .. tostring(latency))
		if not conn then
			ngx.log(ngx.ERR,"failed to record the connection leaving ","request: ", err)
			return
		end
	end
end

return _M
