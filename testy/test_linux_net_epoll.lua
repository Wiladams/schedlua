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

local net = require("linux_net"){importglobal=true}
local errnos = require("linux_errno")

local server_address = "127.0.0.1"
local server_port = 13;

local epoll = require("epoll")()


local function main()
	local epset = epoll.epollset();

	-- create socket and make it non-blocking
	local s = net.bsdsocket(SOCK_STREAM);
	s:setNonBlocking(true);

	-- add the socket to the epoll set to be watched
	local event = ffi.new("struct epoll_event")
	event.data.fd = s.sockfd;
  	event.events = bor(EPOLLOUT,EPOLLRDHUP, EPOLLERR, EPOLLET); -- EPOLLET
  	epset:add(s.sockfd, event)
 
 	-- connect the socket to the server
 	-- we could get WOULDBLOCK, or EAGAIN
	local sa, err = net.sockaddr_in(server_address, server_port);
	local success, err =  net.connect(s, sa)
	if not success then
		if err ~= errnos.EINPROGRESS then
			print("connect, error", err);
		end
	end

	-- now wait for the socket to be writable
	--
	local maxevents = 10;
	local events = ffi.new("struct epoll_event[?]", maxevents);
	local timeout = -1;		-- wait forever
	success, err = epset:wait(events, 1, timeout);
	--print("epoll waiting for writable (EPOLLOUT): ", success, err)

	--print(string.format("    writable: 0x%x", events[0].events));

	-- modify the socket event registration
	event.events = bor(EPOLLIN,EPOLLRDHUP, EPOLLERR); 
	epset:modify(s.sockfd, event);

	local BUFSIZ = 512;
	local buffer = ffi.new("char[512+1]");
	local bytesRead = 0
	

	-- Now that the socket is ready, we can wait for it to 
	-- be readable, and do a read
	repeat
		bytesRead = 0;

		success, err = epset:wait(events, maxevents, timeout);
		--print("read epoll wait: ", success, err)
		if not success then
			return false, err;
		end

		for i=0,success-1 do
			--print(string.format("event - fd: %d, events: 0x%x", events[i].data.fd, events[i].events));
			
			if band(events[i].events, EPOLLIN) > 0 then
				bytesRead, err = s:read(buffer, BUFSIZ);
				--print("bytes read: ", bytesRead, err)

				if bytesRead then
					local str = ffi.string(buffer, bytesRead);
					io.write(str);
				else
					if err ~= errnos.EWOULDBLOCK then
						print("read, error: ", err)
						return false, err;
					end
				end
			end

			if band(events[i].events, EPOLLRDHUP) > 0 then
				--print("RDHUP!!")
				bytesRead = 0;
			end
		end

	until bytesRead < 1
end

main()
