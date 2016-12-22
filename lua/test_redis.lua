local redis = require("resty.redis")
local cjson = require("cjson")
local cjson_encode = cjson.encode
local ngx_log = ngx.log
local ngx_ERR = ngx.ERR
local ngx_exit = ngx.exit
local ngx_print = ngx.print
local ngx_re_match = ngx.re.match
local ngx_var = ngx.var
local redis_key = "lua_"

local function close_redis(red)
    if not red then
        return
    end
    --释放连接(连接池实现)
    local pool_max_idle_time = 10000 --毫秒
    local pool_size = 100 --连接池大小
    local ok, err = red:set_keepalive(pool_max_idle_time, pool_size)

    if not ok then
        ngx_log(ngx_ERR, "set redis keepalive error : ", err)
    end
end
local function read_redis(id)
    local red = redis:new()
    red:set_timeout(1000)
    local ip = "172.28.29.15"
    local port = 6379
    local ok, err = red:connect(ip, port)
    if not ok then
        ngx_log(ngx_ERR, "connect to redis error : ", err)
        return close_redis(red)
    end

    local resp, err = red:get(redis_key..tostring(id))
    if not resp then
        ngx_log(ngx_ERR, "get redis content error : ", err)
        return close_redis(red)
    end
    --得到的数据为空处理
    if resp == ngx.null then
        resp = nil
	local ok, err = red:set(redis_key..tostring(id), id)
        if not ok then
           ngx.say("failed to set redis: ", err)
           return
        end
    end
    close_redis(red)
    ngx.say(resp)
    return resp
end

local function read_http(id)
    ngx_log(ngx_ERR,"========",id)
    if id == nil then 
	return "not from redis!"
    else 
	return "get from redis!"
    end

    local resp = ngx.location.capture("/test", {
        method = ngx.HTTP_GET,
        args = {id = id}
    })

    if not resp then
        ngx_log(ngx_ERR, "request error :", err)
        return
    end

    if resp.status ~= 200 then
        ngx_log(ngx_ERR, "request error, status :", resp.status)
        return
    end

    return resp.body
end


--获取id
local id = ngx_var.arg_id

--从redis获取
local content = read_redis(id)

--如果redis没有，回源到tomcat
content = read_http(content)
ngx.say(content)

--如果还没有返回404
if not content then
   ngx_log(ngx_ERR, "http not found content, id : ", id)
   return ngx_exit(404)
end

--输出内容
