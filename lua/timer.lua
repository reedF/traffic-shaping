-- nginx.conf: in "http" to setting: 
-- init_worker_by_lua_file lua/timer.lua

local delay = 120  -- in seconds
local new_timer = ngx.timer.at
local log = ngx.log
local INFO = ngx.INFO
local ERR = ngx.ERR
local handler
handler = function(premature,var)
  -- do business
  log(INFO,"=======>timer work!===" .. ngx.worker.pid() .. "===" .. tostring(premature) .. "===" ..var)  
  if premature then
     -- nginx reload: premature==true
     return  
  end
  if 0 == ngx.worker.id() then
     local ok, err = new_timer(delay, handler,"test")
     if not ok then
        log(ERR, "failed to create timer: ", err)
        return
     end
  end
end
if 0 == ngx.worker.id() then
    local ok, err = new_timer(1, handler,"test")
    if not ok then
       log(ERR, "failed to create timer: ", err)
       return
    end
end