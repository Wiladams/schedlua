--test_async_socket.lua
package.path = package.path..";../?.lua"

--[[
	Simple networking test case.
	Implement a client that will do a basic HTTP GET to any 
	given url.  It will read results back until the socket 
	is closed.

	This does not do any http parsing.
--]]
local ffi = require("ffi")


local Kernel = require("kernel");
local AsyncSocket = require("AsyncSocket")

local servername = arg[1] or "www.bing.com"

local function httpRequest(s)
	local request = string.format("GET / HTTP/1.1\r\nUser-Agent: schedlua (linux-gnu)\r\nAccept: */*\r\nHost: %s\r\nConnection: close\r\n\r\n", servername);

	io.write(request)
	print("===================")

	return s:write(request, #request);
end

local function httpResponse(s)
	local BUFSIZ = 512;
	local buffer = ffi.new("char[512+1]");
	local bytesRead = 0
	local err = nil;

	repeat
		bytesRead = 0;

		bytesRead, err = s:read(buffer, BUFSIZ);

		if bytesRead then
			local str = ffi.string(buffer, bytesRead);
			io.write(str);
		else
			print("read, error: ", err)
			break;
		end

	until bytesRead < 1
end


local function probeHttp(s)
	httpRequest(s);
	httpResponse(s);

	Kernel:halt();
end

local function main()
	local s = AsyncSocket();
	if not s:connect(servername, 80) then
		print("connection error")
		return false;
	end  

	Kernel:spawn(probeHttp, s)
end

Kernel:run(main)
