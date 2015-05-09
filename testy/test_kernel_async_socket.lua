--test_linux_net.lua
package.path = package.path..";../?.lua"

--[[
	Simple networking test case.
	Implement a client to the daytime service (port 13)
	Make a basic TCP connection, read data, finish
--]]
local ffi = require("ffi")
local bit = require("bit")
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift




local Kernel = require("kernel"){makeGlobal = true};
local epoll = require("epoll")()
local asyncio = require("asyncio")
asyncio{Kernel = Kernel, exportglobal = true, AutoStart=true}

local net = require("linux_net"){exportglobal=true}
local errnos = require("linux_errno"){exportglobal=true}



local function async_connect(sock, sa)
	local success, err =  net.connect(sock, sa)
	--print("async_connect(): ",success, err, EINPROGRESS)

	if not success then
		if err ~= EINPROGRESS then
			print("connect, error", err);
			return false, err;
		end
	end

	-- now wait for the socket to be writable
	--
  	--print("async_connect(), 2.0")
	local event = ffi.new("struct epoll_event")
	event.data.fd = sock.sockfd;
  	event.events = bor(EPOLLOUT,EPOLLRDHUP, EPOLLERR, EPOLLET); -- EPOLLET

	local success, err = asyncio:waitForIOEvent(sock.sockfd, event);

  	--print("async_connect(), 3.0: ", success, err)

	return success, err;
end

local function async_read(sock, buff, bufflen)
	local event = ffi.new("struct epoll_event")
	event.data.fd = sock.sockfd;
	event.events = bor(EPOLLIN,EPOLLRDHUP, EPOLLERR); 

	local success, err = asyncio:waitForIOEvent(sock.sockfd, event);
--[[
	if not success then
		return false, err;
	end
--]]
	local bytesRead = 0;

	--if band(success, EPOLLIN) > 0 then
		bytesRead, err = sock:read(buff, bufflen);
		--print("async_read(), bytes read: ", bytesRead, err)
	--	return bytesRead, err;
	--end

	return bytesRead, err;
end


local function main()
	local server_address = "127.0.0.1"
	local server_port = 13;


	-- create socket and make it non-blocking
	local s = net.bsdsocket(SOCK_STREAM);
	s:setNonBlocking(true);

	-- add the socket to the epoll set to be watched
 	local success, err = asyncio:watchForIOEvents(s.sockfd);
	--print("main(), watchForIO", success, err);

 	-- connect the socket to the server
 	-- we could get WOULDBLOCK, or EAGAIN
	local sa, err = net.sockaddr_in(server_address, server_port);
	success, err = async_connect(s, sa)



	local BUFSIZ = 512;
	local buffer = ffi.new("char[512+1]");
	local bytesRead = 0
	

	-- Now that the socket is ready, we can wait for it to 
	-- be readable, and do a read
	repeat
		bytesRead = 0;

		bytesRead, err = async_read(s, buffer, BUFSIZ);

		if bytesRead then
			local str = ffi.string(buffer, bytesRead);
			io.write(str);
		else
			if err ~= EWOULDBLOCK then
				print("read, error: ", err)
				return false, err;
			end
		end

	until bytesRead < 1

	Kernel:halt();
end

run(main)
