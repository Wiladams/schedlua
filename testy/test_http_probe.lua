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
local sites = require("sites");
local alarm = require("alarm")(Kernel)


local function httpRequest(s, sitename)
	local request = string.format("GET / HTTP/1.1\r\nUser-Agent: schedlua (linux-gnu)\r\nAccept: */*\r\nHost: %s\r\nConnection: close\r\n\r\n", sitename);
	
	print("==== httpRequest ====")
	io.write(request)

	local success, err = s:write(request, #request);
	print("RETURN: ", success, err);
	print("---------------------");

	return success, err;
end

local function httpResponse(s)
	local BUFSIZ = 512;
	local buffer = ffi.new("char[512+1]");
	local bytesRead = 0
	local err = nil;


	-- Now that the socket is ready, we can wait for it to 
	-- be readable, and do a read
	print("==== httpResponse ====")
	repeat
		bytesRead = 0;

		bytesRead, err = s:read(buffer, BUFSIZ);

		if bytesRead then
			local str = ffi.string(buffer, bytesRead);
			print(bytesRead)
			--io.write(str);
		else
			print("read, error: ", err)
			break;
		end

	until bytesRead < 1

	print("-----------------")
end


local function probeSite(sitename)
	-- lookup the site ip address
	print("==== probeSite : ", sitename);

	local s = net.AsyncSocket();

	success, err = s:connect(sitename, 80);  

	if not success then
		print("connect, error: ", err);
		return false, err
	end

	-- issue a request so we have something to read
	httpRequest(s, sitename);
	httpResponse(s);
end

local function stopProgram()
	Kernel:halt();
end

local function main()
	local maxProbes = 100;

	alarm:delay(stopProgram, 1000*120)
	
	for idx=1,maxProbes do
		Kernel:spawn(probeSite, sites[idx])
	end
end

Kernel:run(main)
