-- setting nginx.conf in "http" phase:lua_shared_dict dict_rule_conn 1m;
local limit_conn = require "resty.limit.conn"


local _M = {
    _VERSION = '1.0',
}

local mt = { __index = _M }

-- limit the requests under 200 concurrent requests (normally just
-- incoming connections unless protocols like SPDY is used) with
-- a burst of 100 extra concurrent requests, that is, we delay
-- requests under 300 concurrent connections and above 200
-- connections, and reject any new requests exceeding 300
-- connections.
-- also, we assume a default request time of 0.5 sec, which can be
-- dynamically adjusted by the leaving() call in log_by_lua below.
function _M.check_conn()
	local lim, err = limit_conn.new("dict_rule_conn", 20, 10, 0.5)
	if not lim then
		ngx.log(ngx.ERR,"failed to instantiate a resty.limit.conn object: ", err)
		return ngx.exit(500)
	end

	-- the following call must be per-request.
	-- here we use the host as the limiting key
	local key = ngx.var.host
	local delay, err = lim:incoming(key, true)
	ngx.log(ngx.INFO,"============>" .. tostring(delay) .. "===" .. tostring(err))
	if not delay then
		if err == "rejected" then
			return ngx.exit(503)
		end
		ngx.log(ngx.ERR, "failed to limit req: ", err)
		return ngx.exit(500)
	end

	if lim:is_committed() then
		local ctx = ngx.ctx
		ctx.limit_conn = lim
		ctx.limit_conn_key = key
		ctx.limit_conn_delay = delay
	end

	-- the 2nd return value holds the current concurrency level
	-- for the specified key.
	local conn = err

	if delay >= 0.001 then
		-- the request exceeding the 200 connections ratio but below
		-- 300 connections, so
		-- we intentionally delay it here a bit to conform to the
		-- 200 connection limit.
		-- ngx.log(ngx.WARN, "delaying")
		ngx.sleep(delay)
	end
end

function _M.logger() 
	local ctx = ngx.ctx
    local lim = ctx.limit_conn
    if lim then
		-- if you are using an upstream module in the content phase,
		-- then you probably want to use $upstream_response_time
		-- instead of ($request_time - ctx.limit_conn_delay) below.
		local latency = tonumber(ngx.var.request_time) - ctx.limit_conn_delay
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