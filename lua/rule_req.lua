local limit_req = require "resty.limit.req"

-- ������������Ϊ200 req/sec����������100 req/sec��ͻ������
-- ����˵���ǻ��200����300һ�µ�����������ӳ�
-- ����300�����󽫻ᱻ�ܾ�
local lim, err = limit_req.new("dict_rule_req", 20, 10)
if not lim then 
	--����limit_req����ʧ��
	ngx.log(ngx.ERR,"failed to instantiate a resty.limit.req object: ", err)
	return ngx.exit(500)
end

-- ����������ÿһ������������
-- ʹ��ip��ַ��Ϊ������key
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
-- �ڶ�������(err)�����ų����������ʵ�������
-- ����err����31����ζ�ŵ�ǰ������231 req/sec
local excess = err

-- ��ǰ���󳬹�200 req/sec ��С�� 300 req/sec
-- �������sleepһ�£���֤������200 req/sec�������ӳٴ���
ngx.sleep(delay) --������sleep(��)
end
