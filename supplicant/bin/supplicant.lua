#!/usr/bin/lua

nixio = require "nixio"
bit = require "nixio".bit
md5 = require "md5"
--iconv = require "iconv"

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

--转换无符号32位整数为int32
function uint2int (uint)
    local rs=uint
    --获取符号位
    local signed = bit.rshift(uint,31)       
        if signed > 0 then  --负数
        rs = bit.band(bit.bnot(uint), 0x7fffffff) + 1
        rs = -1 * rs
    end 
    return rs   
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

function search_service(socket, mac_addr, host_ip)
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
	
	socket:sendto(table.concat(bpacket), host_ip, port)
	--接收报文
	local recv_msg = socket:recv(port)
	local recv_packet = {}
	for i=1,string.len(recv_msg) do
		recv_packet[i] = string.byte(string.sub(recv_msg,i,i))
	end
	
	decrypt(recv_packet)
	
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
end

function search_server_ip(socket, mac_addr, ip)
	local packet_len = 1 + 1 + 16 + 1 + 1 + 5 + 1 + 1 + 16 + 1 + 1 + 6;
	local packet = {};
	
	table.insert(packet, 0x0c)
	table.insert(packet, packet_len)
	for i=1,16 do
		table.insert(packet, 0)
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
		table.insert(packet,0)
	end
	
	table.insert(packet,0x07)
	table.insert(packet,0x08)
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
	
	--发送报文
	socket:sendto(table.concat(bpacket), '1.1.1.8', 3850)
	--接收报文
	local recv_msg = socket:recv(3850)
	local recv_packet = {}
	for i=1,string.len(recv_msg) do
		recv_packet[i] = string.byte(string.sub(recv_msg,i,i))
	end
	
	decrypt(recv_packet)

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
end

function generate_upnet(mac_addr, ip, user, pwd, dhcp, service, version)
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
		table.insert(packet,0)
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
	
    --for k,v in ipairs(packet) do io.write(v,', ') end
	
	local bpacket = {}
	for k,v in ipairs(packet) do
		table.insert(bpacket,string.char(v))
	end
    return table.concat(bpacket)
end

function upnet(socket, packet)
	--发送报文
    socket:sendto(packet, host_ip, port)
	--接收报文
    local recv_msg = socket:recv(port)
	if(type(recv_msg) == "boolean") then
		return nil
	end
	local recv_packet = {}
	for i=1,string.len(recv_msg) do
		recv_packet[i] = string.byte(string.sub(recv_msg,i,i))
	end
	
    decrypt(recv_packet)
	
    status = recv_packet[21]
    session_len = recv_packet[23]
    session = table.sub(recv_packet, 24, session_len + 24 - 1)
	pos = table.find(recv_packet, 11, 36)
    message_len = recv_packet[pos + 1]
	message = table.sub(recv_packet, pos + 2, message_len + pos + 2 - 1)
	msg = {}
	for k,v in ipairs(message) do
		table.insert(msg,string.char(v))
	end
	msg_str = table.concat(msg)
	--trans = iconv.new("utf-8","gbk")
	--msg_str = trans:iconv(msg_str)
    --print(msg_str)
    if(status==0) then
        return nil
    else
		--print("Login Success!")
		return session
	end
end

function generate_breathe(mac_addr, ip, session, index)
    index = string.format("%x",index)
    local packet = {}
	table.insert(packet, 3) --3 保持在线  5 请求下线  1 请求上线
    local packet_len = #(session) + 88
	table.insert(packet, packet_len)
	for i=1,16 do
		table.insert(packet, 0)
	end
	table.insert(packet, 8)
	table.insert(packet, #(session) + 2)
	for k,v in ipairs(session) do      
		table.insert(packet, v)
	end
	table.insert(packet, 9)
	table.insert(packet, 18)
	for i=1,string.len(ip) do      
		table.insert(packet,string.byte(string.sub(ip,i,i)))
	end
	for i=1,16-string.len(ip) do      
		table.insert(packet,0)
	end
	table.insert(packet,7)
	table.insert(packet,8)
	for k,v in ipairs(string.split(mac_addr,':')) do
		table.insert(packet,string.format("%d","0x"..v))
	end
	table.insert(packet,20)
	table.insert(packet,6)
	
	local len = string.len(index)
	table.insert(packet,string.format("%d","0x"..string.sub(index,len-7,len-6)))
	table.insert(packet,string.format("%d","0x"..string.sub(index,len-5,len-4)))
	table.insert(packet,string.format("%d","0x"..string.sub(index,len-3,len-2)))
	table.insert(packet,string.format("%d","0x"..string.sub(index,len-1,len-0)))
	
	table.insert(packet,42)
	table.insert(packet,6)
	table.insert(packet,0)
	table.insert(packet,0)
	table.insert(packet,0) 
	table.insert(packet,0)
	
	table.insert(packet,43)
	table.insert(packet,6)
	table.insert(packet,0)
	table.insert(packet,0)
	table.insert(packet,0)
	table.insert(packet,0)
	
	table.insert(packet,44)
	table.insert(packet,6)
	table.insert(packet,0)
	table.insert(packet,0)
	table.insert(packet,0)
	table.insert(packet,0)
	
	table.insert(packet,45)
	table.insert(packet,6)
	table.insert(packet,0)
	table.insert(packet,0)
	table.insert(packet,0)
	table.insert(packet,0)
	
	table.insert(packet,46)
	table.insert(packet,6)
	table.insert(packet,0)
	table.insert(packet,0)
	table.insert(packet,0)
	table.insert(packet,0)
	
	table.insert(packet,47)
	table.insert(packet,6)
	table.insert(packet,0)
	table.insert(packet,0)
	table.insert(packet,0)
	table.insert(packet,0)
	
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

function breathe(socket, mac_addr, ip, session, index)
    sleep(0) 
    while(true) do
        local breathe_packet = generate_breathe(mac_addr, ip, session, index)
        socket:sendto(breathe_packet, host_ip, port)
		local breathe_recv = socket:recv(port)
		local recv_packet = {}
		for i=1,string.len(breathe_recv) do
			recv_packet[i] = string.byte(string.sub(breathe_recv,i,i))
		end
		decrypt(recv_packet)
	
		status = recv_packet[21]
		if status == 0 then
			break;
		end
		index = index + 3
		sleep(30)
	end
end

function generate_downnet(mac_addr, ip, session, index)
    index = string.format("%x",index)
    local packet = {}
	table.insert(packet, 5) -- 5 请求下线  3 保持在线  1 请求上线
    local packet_len = #(session) + 88
	table.insert(packet, packet_len)
	for i=1,16 do
		table.insert(packet, 0)
	end
	table.insert(packet, 8)
	table.insert(packet, #(session) + 2)
	for k,v in ipairs(session) do      
		table.insert(packet, v)
	end
	table.insert(packet, 9)
	table.insert(packet, 18)
	for i=1,string.len(ip) do      
		table.insert(packet,string.byte(string.sub(ip,i,i)))
	end
	for i=1,16-string.len(ip) do      
		table.insert(packet,0)
	end
	table.insert(packet,7)
	table.insert(packet,8)
	for k,v in ipairs(string.split(mac_addr,':')) do
		table.insert(packet,string.format("%d","0x"..v))
	end
	table.insert(packet,20)
	table.insert(packet,6)
	
	local len = string.len(index)
	table.insert(packet,string.format("%d","0x"..string.sub(index,len-7,len-6)))
	table.insert(packet,string.format("%d","0x"..string.sub(index,len-5,len-4)))
	table.insert(packet,string.format("%d","0x"..string.sub(index,len-3,len-2)))
	table.insert(packet,string.format("%d","0x"..string.sub(index,len-1,len-0)))
	
	table.insert(packet,42)
	table.insert(packet,6)
	table.insert(packet,0)
	table.insert(packet,0)
	table.insert(packet,0)
	table.insert(packet,0)
	
	table.insert(packet,43)
	table.insert(packet,6)
	table.insert(packet,0)
	table.insert(packet,0)
	table.insert(packet,0)
	table.insert(packet,0)
	
	table.insert(packet,44)
	table.insert(packet,6)
	table.insert(packet,0)
	table.insert(packet,0)
	table.insert(packet,0)
	table.insert(packet,0)
	
	table.insert(packet,45)
	table.insert(packet,6)
	table.insert(packet,0)
	table.insert(packet,0)
	table.insert(packet,0)
	table.insert(packet,0)
	
	table.insert(packet,46)
	table.insert(packet,6)
	table.insert(packet,0)
	table.insert(packet,0)
	table.insert(packet,0)
	table.insert(packet,0)
	
	table.insert(packet,47)
	table.insert(packet,6)
	table.insert(packet,0)
	table.insert(packet,0)
	table.insert(packet,0)
	table.insert(packet,0)
	
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

function downnet(socket, mac_addr, ip, session, index)
	downet_packet = generate_downnet(mac_addr, ip, session, index)
	socket:sendto(downet_packet, host_ip, port)
	local recv_msg = socket:recv(port)
end

function run()
	index = 0x01000000
	upnet_packet = generate_upnet(mac_addr, ip, username, password, dhcp, service, version)
	session = upnet(socket,upnet_packet)
	if(type(session) == "nil") then
		if(retry_cnt < 3) then
			retry_cnt = retry_cnt + 1;
			run()
		else
			os.execute("rm "..home.."/supplicant.pid")
			--print("Login Error!")
		end
	else
		retry_cnt = 0
		print("Login success!")
		breathe(socket, mac_addr, ip, session, index)
		downnet(socket,mac_addr, ip, session, index)
		if(retry_cnt < 3) then
			retry_cnt = retry_cnt + 1;
			run()
		else
			os.execute("rm "..home.."/supplicant.pid")
			--print("Login Error!")
		end
	end
	
	socket:close();
end

function login_test()
	upnet_packet = generate_upnet(mac_addr, ip, username, password, dhcp, service, version)
	session = upnet(socket,upnet_packet)
	if(type(session) == "nil") then
		--测试三次,如果都失败则删除配置文件
		if(retry_cnt < 3) then
			retry_cnt = retry_cnt + 1
			login_test()
		else
			os.execute("rm "..config_file.." "..authc_file)
		end
	end
end

function init()
	config_file = home.."/bin/conf.lua"
	authc_file = home.."/bin/authc.lua"
	dofile(config_file)
	dofile(authc_file)
	pcall(dofile, config_file)
	pcall(dofile, authc_file)
	retry_cnt = 0;
	port = 3848
	socket = nixio.socket("inet","dgram")
	socket:setopt("socket", "reuseaddr", 1)
	socket:setopt("socket", "rcvtimeo", 10)
	host_ip = search_server_ip(socket, mac_addr, ip)
	service = search_service(socket, mac_addr, host_ip)
end

function main()
	if(string.isNilOrEmpty(arg[1])) then
		init()
		print("Notice: Ctrl + C to exit")
		print("SERVICE: ", service,"\nMAC ADDR: ",mac_addr,"\nLOCAL IP: ", ip,"\nHOST IP: ",host_ip,"\nUSERNAME: ", username, "\nPASSWORD: ", password)	
		run()
	elseif(arg[1] == "-t") then
		init()
		login_test()
	end
end

home = "/usr/share/supplicant"
main()
