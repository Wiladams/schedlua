--test_linux_net.lua
package.path = "../?.lua;"..package.path

--[[
	Simple networking test case.
	Implement a client to the daytime service (port 13)
	Make a basic TCP connection, read data, finish
--]]
local ffi = require("ffi")
local bit = require("bit")
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift


local Kernel = require("schedlua.kernel");
local AsyncSocket = require("schedlua.linux.nativesocket");



local sites = require("sites");


local function httpRequest(s, sitename)
	local request = string.format("GET / HTTP/1.1\r\nUser-Agent: schedlua (linux-gnu)\r\nAccept: */*\r\nHost: %s\r\nConnection: close\r\n\r\n", sitename);
	

	local success, err = s:write(request, #request);
	print("==== httpRequest(), WRITE: ", success, err);
	io.write(request)
	print("---------------------");

	return success, err;
end


local function httpResponse(s)
	local bytesRead = 0
	local err = nil;
	local BUFSIZ = 512;
	local buffer = ffi.new("char[512+1]");


	-- Now that the socket is ready, we can wait for it to 
	-- be readable, and do a read
	print("==== httpResponse ====")
	repeat
		bytesRead = 0;

		bytesRead, err = s:read(buffer, BUFSIZ);

		if bytesRead then
			local str = ffi.string(buffer, bytesRead);
			io.write(str);
		else
			print("==== httpResponse.READ, ERROR: ", err)
			break;
		end

	until bytesRead < 1

	print("-----------------")
end


local function probeSite(sitename)

	local s = AsyncSocket();
	print("==== probeSite : ", sitename, s.fdesc.fd);

	local success, err = s:connect(sitename, 80);  

	if not success then
		print("NO CONNECTION TO: ", sitename, err);
		return false, err
	end
	-- issue a request so we have something to read
	httpRequest(s, sitename);
	httpResponse(s);

	s:close();
end

local function stopProgram()
	halt();
end

local function main()
	local maxProbes = 80;

	delay(1000*10, stopProgram)
	
	for idx=1,maxProbes do
		--probeSite(sites[idx])
		spawn(probeSite, sites[idx])
		yield();
	end
end


local function probeStress()
	alarm:delay(stopProgram, 1000*20)

	for i=1,10 do
		spawn(probeSite, sites[i])
		--probeSite(sites[i])
	end
end

run(main)
--run(probeStress)
