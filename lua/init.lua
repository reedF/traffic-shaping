-- setting nginx.conf:init_by_lua_file lua/init.lua;
-- setting IP rules
local rule_ip = require("rule_ip")
rule_ip.enable_lrucache()
local whitelist_ips = {
    "127.0.0.1",
    "10.10.10.0/24",
    "192.168.0.0/16",
}
 
local blacklist_ips = {
	"172.31.240.135",
    "192.168.0.0/16",
}

global_ip_whitelist = rule_ip.parse_cidrs(whitelist_ips)

global_ip_blacklist = rule_ip.parse_cidrs(blacklist_ips)