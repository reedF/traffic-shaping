local limit_req = require "resty.limit.req"

-- 限制请求速率为200 req/sec，并且允许100 req/sec的突发请求
-- 就是说我们会把200以上300一下的请求请求给延迟
-- 超过300的请求将会被拒绝
local lim, err = limit_req.new("dict_rule_req", 20, 10)
if not lim then 
	--申请limit_req对象失败
	ngx.log(ngx.ERR,"failed to instantiate a resty.limit.req object: ", err)
	return ngx.exit(500)
end

-- 下面代码针对每一个单独的请求
-- 使用ip地址作为限流的key
local key = ngx.var.remote_addr
local delay, err = lim:incoming(key, true)
ngx.log(ngx.INFO,"============>" .. tostring(delay) .. "===" .. tostring(err))
if not delay then
	if err == "rejected" then
		return ngx.exit(503)
	end
	ngx.log(ngx.ERR, "failed to limit req: ", err)
	return ngx.exit(500)
end

if delay > 0 then
-- 第二个参数(err)保存着超过请求速率的请求数
-- 例如err等于31，意味着当前速率是231 req/sec
local excess = err

-- 当前请求超过200 req/sec 但小于 300 req/sec
-- 因此我们sleep一下，保证速率是200 req/sec，请求延迟处理
ngx.sleep(delay) --非阻塞sleep(秒)
end
