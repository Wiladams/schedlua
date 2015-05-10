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


local Kernel = require("kernel")();
local net = require("linux_net")();

local serverip = "204.79.197.200"		-- www.bing.com
local servername = "www.bing.com"

--local servername = "news.ycombinator.com"
--local serverip = "198.41.191.47"		




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


	-- Now that the socket is ready, we can wait for it to 
	-- be readable, and do a read
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

	Kernel:halt();
end


local function main()
	local s = net.AsyncSocket();

	success, err = s:connect(serverip, 80);  

	if not success then
		print("connect, error: ", err);
		return false, err
	end

	-- issue a request so we have something to read
	httpRequest(s);

	httpResponse(s);
end

Kernel:run(main)
