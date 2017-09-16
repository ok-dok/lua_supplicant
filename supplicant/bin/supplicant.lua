#!/usr/bin/lua
nixio = require "nixio"
bit = nixio.bit
md5 = require "md5"
--iconv = require "iconv"
log = {}

function string.split(input, delimiter)  
    local input = tostring(input) 
    local delimiter = tostring(delimiter)  
    if (delimiter=='') then return false end  
    local pos = 0
	local arr = {}  
    -- for each divider found  
	for st,sp in function() return string.find(input,delimiter,pos,true) end do
		table.insert(arr,string.sub(input,pos,st-1))
		pos = sp+1
	end
    table.insert(arr, string.sub(input, pos))  
    return arr  
end

function string.trim(str)
	return (str:gsub("^%s*(.-)%s*$", "%1"))
end

function string.isNilOrEmpty(str)
	if(type(str) == "nil") then
		return true
	elseif(type(str)== "string") then
		if(string.trim(str) == "") then
			return true
		else
			return false
		end
	else
		return true
	end
end

--查找指定数组中的某个元素的位置，如找到则返回索引位置，未找到返回nil
function table.find(_table,_value,_begin,_end)
	local _begin = _begin or 1
	local _end = _end or #(_table)
	for k,v in ipairs(_table) do
		if(k >= _begin and k <= _end and v == _value) then 
			return k
		end
	end
	return nil
end

--对指定数组进行截取，从指定开始位置到结束位置，返回截取后的数组子集
function table.sub(_table,_begin,_end)
	local _begin = _begin or 1
	local _end = _end or #(_table)
	local subtable = {}
	local k = 1
	for i=_begin,_end do
		subtable[k] = _table[i]
		k = k + 1
	end
	return subtable
end

function sleep(n)
   os.execute("sleep " .. n)
end

function log.info(msg)
	log.msg(" [info] "..msg);
end

function log.error(msg)
	log.msg(" [error] "..msg);
end

function log.msg(msg)
	local log_file = io.open(log_file, "a")
	log_file:write(os.date("%m/%d %X",os.time())..msg.."\n")
	log_file:close()
end

function encrypt(buffer)
    for i,v in ipairs(buffer) do
		buffer[i] = bit.bor(bit.rshift(bit.band(buffer[i], 0x80),6),
							bit.rshift(bit.band(buffer[i], 0x40),4),
							bit.rshift(bit.band(buffer[i], 0x20),2),
							bit.lshift(bit.band(buffer[i], 0x10),2),
							bit.lshift(bit.band(buffer[i], 0x08),2),
							bit.lshift(bit.band(buffer[i], 0x04),2),
							bit.rshift(bit.band(buffer[i], 0x02),1),
							bit.lshift(bit.band(buffer[i], 0x01),7))
	end
end

function decrypt(buffer)
    for i,v in ipairs(buffer) do
        buffer[i] = bit.bor(bit.rshift(bit.band(buffer[i], 0x80),7),
							bit.rshift(bit.band(buffer[i], 0x40),2),
							bit.rshift(bit.band(buffer[i], 0x20),2),
							bit.rshift(bit.band(buffer[i], 0x10),2),
							bit.lshift(bit.band(buffer[i], 0x08),2),
							bit.lshift(bit.band(buffer[i], 0x04),4),
							bit.lshift(bit.band(buffer[i], 0x02),6),
							bit.lshift(bit.band(buffer[i], 0x01),1))
	end
end

function search_service(mac_addr)
	local packet_len = 1 + 1 + 16 + 1 + 1 + 5 + 1 + 1 + 6
	local packet = {}
	table.insert(packet, 0x07)
	table.insert(packet, packet_len)
	for i=1,16 do
		table.insert(packet, 0)
	end
	table.insert(packet, 0x08)
	table.insert(packet, 0x07)
	for i=0,4 do
		table.insert(packet,i)
	end
	table.insert(packet, 0x07);
	table.insert(packet, 0x08);
	for k,v in ipairs(string.split(mac_addr,':')) do
		table.insert(packet,string.format("%d","0x"..v))
	end
	
	--将packet内容由整型转换为字节
	local bpacket = {}
	for k,v in ipairs(packet) do
		table.insert(bpacket,string.char(v))
	end
	--摘要计算校验和
	
	local md5str = md5.sumhexa(table.concat(bpacket))
	--将校验和加入到packet[3..18]
	for i=1,string.len(md5str) do
		if(i%2==0) then
			packet[i/2+2] = string.format("%d","0x"..string.sub(md5str,i-1,i))
		end
	end
	
	encrypt(packet);
	
	local bpacket = {}
	for k,v in ipairs(packet) do
		table.insert(bpacket,string.char(v))
	end
	
	local recv_msg = send_recv(table.concat(bpacket))
	if(not recv_msg) then return nil end

	local recv_packet = {}
	for i=1,string.len(recv_msg) do
		recv_packet[i] = string.byte(string.sub(recv_msg,i,i))
	end
	
	decrypt(recv_packet)
	if(check_md5(recv_packet)) then
		--取出服务内容
		local service_index = table.find(recv_packet, 0x0a)
		local service_len = recv_packet[service_index + 1];
		local service_type = table.sub(recv_packet, service_index + 2, service_len + service_index - 1)
		local service = {}
		for k,v in ipairs(service_type) do
			table.insert(service,string.char(v))
		end
		local service_str = table.concat(service)
		return service_str;
	else
		return search_service(mac_addr)
	end

end

function search_server_ip(mac_addr, ip)
	local packet_len = 1 + 1 + 16 + 1 + 1 + 5 + 1 + 1 + 16 + 1 + 1 + 6;
	local packet = {};
	
	table.insert(packet, 0x0c)
	table.insert(packet, packet_len)
	for i=1,16 do
		table.insert(packet, 0x00)
	end
		
	table.insert(packet, 0x08)
	table.insert(packet, 0x07)
	for i=0,4 do
		table.insert(packet,i)
	end
	
	table.insert(packet, 0x09)
	table.insert(packet, 0x12)
	for i=1,string.len(ip) do      
		table.insert(packet,string.byte(string.sub(ip,i,i)))
	end
	for i=1,16-string.len(ip) do      
		table.insert(packet, 0x00)
	end
	
	table.insert(packet, 0x07)
	table.insert(packet, 0x08)
	for k,v in ipairs(string.split(mac_addr,':')) do
		table.insert(packet,string.format("%d","0x"..v))
	end
	
	--将packet内容由整型转换为字节
	local bpacket = {}
	for k,v in ipairs(packet) do
		table.insert(bpacket,string.char(v))
	end
	--摘要计算校验和
	
	local md5str = md5.sumhexa(table.concat(bpacket))
	--将校验和加入到packet[3..18]
	for i=1,string.len(md5str) do
		if(i%2==0) then
			packet[i/2+2] = string.format("%d","0x"..string.sub(md5str,i-1,i))
		end
	end
	
	encrypt(packet);
	
	local bpacket = {}
	for k,v in ipairs(packet) do
		table.insert(bpacket,string.char(v))
	end
	
	local recv_msg = send_recv(table.concat(bpacket))
	if(not recv_msg) then return nil end

	local recv_packet = {}
	for i=1,string.len(recv_msg) do
		recv_packet[i] = string.byte(string.sub(recv_msg,i,i))
	end
	
	decrypt(recv_packet)
	if(check_md5(recv_packet)) then 
		--取出服务器ip
		local server_index = table.find(recv_packet, 0x0c)
		local server_len = recv_packet[server_index + 1];
		local server_ip = table.sub(recv_packet, server_index + 2, server_index + server_len - 1)
		local host_ip = ""
		for k,v in ipairs(server_ip) do
			host_ip = host_ip..tostring(v).."."
		end
		host_ip = string.sub(host_ip,1,string.len(host_ip)-1)
		return host_ip;
	else
		return search_server_ip(mac_addr, ip)
	end
	
end

function generate_login(mac_addr, ip, user, pwd, dhcp, service, version)
	local packet = {}
	table.insert(packet, 0x01) -- 1 请求上线
	packet_len = string.len(user) + 2 + 
				 string.len(pwd) + 2 +
				 string.len(ip) + 2 +
				 string.len(service) + 2 +
				 string.len(dhcp) + 2 +
				 string.len(version) + 2 +
				 16 + 2 + 
				 6 + 2
	table.insert(packet,packet_len)
	for i=1,16 do
		table.insert(packet, 0x00)
	end
	
	table.insert(packet, 0x07)
	table.insert(packet, 0x08)
	for k,v in ipairs(string.split(mac_addr,':')) do
		table.insert(packet,string.format("%d","0x"..v))
	end
	
	table.insert(packet, 0x01)
	table.insert(packet,string.len(user) + 2)
	for i=1,string.len(user) do      
		table.insert(packet,string.byte(string.sub(user,i,i)))
	end
	
	table.insert(packet, 0x02)
	table.insert(packet,string.len(pwd) + 2)
	for i=1,string.len(pwd) do      
		table.insert(packet,string.byte(string.sub(pwd,i,i)))
	end
	
	table.insert(packet, 0x09)
	table.insert(packet,string.len(ip) + 2)
	for i=1,string.len(ip) do      
		table.insert(packet,string.byte(string.sub(ip,i,i)))
	end
	
	table.insert(packet, 0x0a)
	table.insert(packet, string.len(service) + 2)
	for i=1,string.len(service) do      
		table.insert(packet,string.byte(string.sub(service,i,i)))
	end
	
	table.insert(packet, 0x0e)
	table.insert(packet, string.len(dhcp) + 2)
	for i=1,string.len(dhcp) do      
		table.insert(packet,tonumber(string.sub(dhcp,i,i)))
	end
	
	table.insert(packet, 0x1f)
	table.insert(packet, string.len(version) + 2)
	for i=1,string.len(version) do      
		table.insert(packet,string.byte(string.sub(version,i,i)))
	end
	
	--将packet内容由整型转换为字节
	local bpacket = {}
	for k,v in ipairs(packet) do
		table.insert(bpacket,string.char(v))
	end
	--摘要计算校验和
	
	local md5str = md5.sumhexa(table.concat(bpacket))
	--将校验和加入到packet[3..18]
    for i=1,string.len(md5str) do
		if(i%2==0) then
			packet[i/2+2] = string.format("%d","0x"..string.sub(md5str,i-1,i))
		end
	end
	
    encrypt(packet)
	
	local bpacket = {}
	for k,v in ipairs(packet) do
		table.insert(bpacket,string.char(v))
	end
    return table.concat(bpacket)
end

function login(packet)
	local recv_msg = send_recv(packet)
	if(not recv_msg) then 
		net_status = -2
		return nil
	end
	local recv_packet = {}
	for i=1,string.len(recv_msg) do
		recv_packet[i] = string.byte(string.sub(recv_msg,i,i))
	end
	
    decrypt(recv_packet)
	--md5校验
	if(check_md5(recv_packet)) then
		status = recv_packet[21]
		session_len = recv_packet[23]
		session = table.sub(recv_packet, 24, session_len + 24 - 1)
		pos = table.find(recv_packet, 0x0b, session_len + 24)
		message_len = recv_packet[pos + 1]
		message = table.sub(recv_packet, pos + 2, message_len + pos + 2 - 1)
		msg = {}
		for k,v in ipairs(message) do
			table.insert(msg,string.char(v))
		end
		msg_str = table.concat(msg)
		--trans = iconv.new("utf-8","gbk")
		--msg_str = trans:iconv(msg_str)
		--log(msg_str)
		if(status==0) then
			--认证出错，可能是用户名密码错误，也可能是不在上网时段，
			--或者不是有效用户，或者被管理员禁止认证
			--具体原因在msg_str中给出，但需要gbk解码
			net_status = -3
			return nil
		else
			net_status = 1
			return session
		end
	else
		net_status = -1
		return nil
	end
    
end

function generate_breathe(mac_addr, ip, session, index)
    index = string.format("%x",index)
    local packet = {}
	table.insert(packet, 0x03) --3 保持在线  5 请求下线  1 请求上线
    local packet_len = #(session) + 88
	table.insert(packet, packet_len)
	for i=1,16 do
		table.insert(packet, 0x00)
	end
	table.insert(packet, 0x08)
	table.insert(packet, #(session) + 2)
	for k,v in ipairs(session) do      
		table.insert(packet, v)
	end
	table.insert(packet, 0x09)
	table.insert(packet, 0x12)
	for i=1,string.len(ip) do      
		table.insert(packet,string.byte(string.sub(ip,i,i)))
	end
	for i=1,16-string.len(ip) do      
		table.insert(packet,0x00)
	end
	table.insert(packet, 0x07)
	table.insert(packet, 0x08)
	for k,v in ipairs(string.split(mac_addr,':')) do
		table.insert(packet,string.format("%d","0x"..v))
	end
	table.insert(packet, 0x14)
	table.insert(packet, 0x06)
	
	local len = string.len(index)
	table.insert(packet,string.format("%d","0x"..string.sub(index,len-7,len-6)))
	table.insert(packet,string.format("%d","0x"..string.sub(index,len-5,len-4)))
	table.insert(packet,string.format("%d","0x"..string.sub(index,len-3,len-2)))
	table.insert(packet,string.format("%d","0x"..string.sub(index,len-1,len-0)))
	
	local block = { 0x2a, 0x06, 0, 0, 0, 0, 
					0x2b, 0x06, 0, 0, 0, 0, 
					0x2c, 0x06, 0, 0, 0, 0, 
					0x2d, 0x06, 0, 0, 0, 0, 
					0x2e, 0x06, 0, 0, 0, 0, 
					0x2f, 0x06, 0, 0, 0, 0}

	for k,v in ipairs(block) do
		table.insert(packet, v)
	end
	
	--将packet内容由整型转换为字节
	local bpacket = {}
	for k,v in ipairs(packet) do
		table.insert(bpacket,string.char(v))
	end
	--摘要计算校验和
	
	local md5str = md5.sumhexa(table.concat(bpacket))
	--将校验和加入到packet[3..18]
    for i=1,string.len(md5str) do
		if(i%2==0) then
			packet[i/2+2] = string.format("%d","0x"..string.sub(md5str,i-1,i))
		end
	end
	
    encrypt(packet)
	
     --for k,v in ipairs(packet) do io.write(v,', ') end
	
	local bpacket = {}
	for k,v in ipairs(packet) do
		table.insert(bpacket,string.char(v))
	end
    return table.concat(bpacket)
end

function breathe(mac_addr, ip, session, index)
    sleep(20)
	md5err_cnt = 0
    while(true) do
		local breathe_packet = generate_breathe(mac_addr, ip, session, index)
		
		local recv_msg = send_recv(breathe_packet)
		if(not recv_msg) then
			net_status = -4
			return nil 
		end
		
		local recv_packet = {}
		for i=1,string.len(recv_msg) do
			recv_packet[i] = string.byte(string.sub(recv_msg,i,i))
		end
		decrypt(recv_packet)
		if(check_md5(recv_packet)) then
			status = recv_packet[21]
			if status == 1 then
				--在线
				net_status = 1
			else
				--呼吸出错
				net_status = -6
				md5err_cnt = md5err_cnt + 1
				if(md5err_cnt >= 3) then
					return
				end
			end
		else
			net_status = -5
		end
		index = index + 3
		sleep(20)
	end
end

function generate_logout(mac_addr, ip, session, index)
    index = string.format("%x",index)
    local packet = {}
	table.insert(packet, 0x05) -- 5 请求下线  3 保持在线  1 请求上线
    local packet_len = #(session) + 88
	table.insert(packet, packet_len)
	for i=1,16 do
		table.insert(packet, 0x00)
	end
	table.insert(packet, 0x08)
	table.insert(packet, #(session) + 2)
	for k,v in ipairs(session) do      
		table.insert(packet, v)
	end
	table.insert(packet, 0x09)
	table.insert(packet, 0x12)
	for i=1,string.len(ip) do      
		table.insert(packet,string.byte(string.sub(ip,i,i)))
	end
	for i=1,16-string.len(ip) do      
		table.insert(packet, 0x00)
	end
	table.insert(packet, 0x07)
	table.insert(packet, 0x08)
	for k,v in ipairs(string.split(mac_addr,':')) do
		table.insert(packet,string.format("%d","0x"..v))
	end
	table.insert(packet, 0x14)
	table.insert(packet, 0x06)
	
	local len = string.len(index)
	table.insert(packet,string.format("%d","0x"..string.sub(index,len-7,len-6)))
	table.insert(packet,string.format("%d","0x"..string.sub(index,len-5,len-4)))
	table.insert(packet,string.format("%d","0x"..string.sub(index,len-3,len-2)))
	table.insert(packet,string.format("%d","0x"..string.sub(index,len-1,len-0)))
	
	
	local block = { 0x2a, 0x06, 0, 0, 0, 0, 
					0x2b, 0x06, 0, 0, 0, 0, 
					0x2c, 0x06, 0, 0, 0, 0, 
					0x2d, 0x06, 0, 0, 0, 0, 
					0x2e, 0x06, 0, 0, 0, 0, 
					0x2f, 0x06, 0, 0, 0, 0}

	for k,v in ipairs(block) do
		table.insert(packet, v)
	end
	
	--将packet内容由整型转换为字节
	local bpacket = {}
	for k,v in ipairs(packet) do
		table.insert(bpacket,string.char(v))
	end
	--摘要计算校验和
	
	local md5str = md5.sumhexa(table.concat(bpacket))
	--将校验和加入到packet[3..18]
    for i=1,string.len(md5str) do
		if(i%2==0) then
			packet[i/2+2] = string.format("%d","0x"..string.sub(md5str,i-1,i))
		end
	end
	
    encrypt(packet)
	
	local bpacket = {}
	for k,v in ipairs(packet) do
		table.insert(bpacket,string.char(v))
	end
    return table.concat(bpacket)
end

function logout(mac_addr, ip, session, index)
	index = index + 3
	logout_packet = generate_logout(mac_addr, ip, session, index)
	send(logout_packet)
	local recv_msg = receive()
	net_status = 0 --下线
end

--接收报文
function receive()
	local recv_msg = udp:recv(4096)
	return recv_msg
end

--发送报文
function send(msg)
	udp:send(msg)
end

--发送并接收
function send_recv(msg)
	local time_out_cnt = 3
	local recv_msg = nil
	while(time_out_cnt > 0) do
		--发送报文
		send(msg)
		--接收报文
		recv_msg = receive()
		if(recv_msg) then break end
		time_out_cnt = time_out_cnt - 1
	end
	return recv_msg
end

--md5校验
function check_md5(packet)
	local recv_md5 = {}
	for i=3, 18 do
		table.insert(recv_md5,packet[i])
		packet[i] = 0x00
	end
	print()
	--将packet内容由整型转换为字节
	local bpacket = {}
	for k,v in ipairs(packet) do
		table.insert(bpacket,string.char(v))
	end
	local md5str = md5.sumhexa(table.concat(bpacket))
	local md5_packet = {}
	for i=1,string.len(md5str) do
		if(i%2==0) then
			md5_packet[i/2] = string.format("%d","0x"..string.sub(md5str,i-1,i))
		end
	end
	return table.concat(md5_packet) == table.concat(recv_md5)
end

function run()
	retry_cnt = 0
	local flag = init()
	while(flag) do
		connect()
		if(net_status == -3) then
			log.error("Authentication failure： The authentication information is incorrect, or not in time period.")
			flag = false;
		elseif(net_status == -2 or net_status == -1) then
			retry_cnt = retry_cnt + 1
			if(retry_cnt > 5) then
				log.error("Authentication failure： connect timeout, please try again later！")
				flag = false;
			end
		else
			retry_cnt = retry_cnt + 1
			if(retry_cnt > 5) then
				log.error("Hold on connecting failed, please try again later！")
				flag = false;
			end
		end
	end
	udp:close();
end

function connect()
	net_status = 0;
	index = 0x01000000
	login_packet = generate_login(mac_addr, ip, username, password, dhcp, service, version)
	session = login(login_packet)
	if(session) then
		retry_cnt = 0
		log.info("Connecting the internet success！")
		breathe(mac_addr, ip, session, index)
		if(net_status ~= 1) then
			logout(mac_addr, ip, session, index)
		end
	end
end

function login_test()
	init()
	login_packet = generate_login(mac_addr, ip, username, password, dhcp, service, version)
	local cnt = 3
	while(cnt > 0) do
		session = login(login_packet)
		if(session) then break end
		cnt = cnt - 1
	end
	
	if(not session) then
		os.execute("rm "..authc_file)
	end
end

function init()
	dofile(config_file)
	dofile(authc_file)
	pcall(dofile, config_file)
	pcall(dofile, authc_file)
	retry_cnt = 0;
	port = 3848

	udp = nixio.socket("inet","dgram")
	udp:setopt("socket","reuseaddr",1)
	udp:setopt("socket","rcvtimeo",10)
	udp:connect("1.1.1.8", 3850)
	ip = udp:getsockname()

	os.execute("echo -n > "..log_file)
	log.info("MAC Addr: "..mac_addr)
	log.info("Local IP: "..ip)
	log.info("Username: "..username)
	log.info("Password: "..password)

	host_ip = search_server_ip(mac_addr, ip)
	if(string.isNilOrEmpty(host_ip)) then
		log.error("Failed to search for server host ip.")
		return false
	end

	log.info("Server IP: "..host_ip)
	--udp:setpeername(host_ip, port)
	udp:connect(host_ip, port)
	service = search_service(mac_addr)
	if(string.isNilOrEmpty(service)) then
		log.error("Failed to search internet service.")
		return false
	end

	log.info("Service: "..service)
	return true
end

function main()
	if(string.isNilOrEmpty(arg[1])) then
		run()
	elseif(arg[1] == "-t") then
		login_test()
	end
end

home = "/usr/share/supplicant"
config_file = home.."/bin/conf.lua"
authc_file = home.."/bin/authc.lua"
log_file = home.."/info.log"
net_status = 0
main()
