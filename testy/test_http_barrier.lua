--test_linux_net.lua
package.path = package.path..";../?.lua"

local ffi = require("ffi")

local Kernel = require("kernel"){exportglobal = true}
local predicate = require("predicate")(Kernel, true)
local AsyncSocket = require("AsyncSocket")

local sites = require("sites");

-- list of tasks
local taskList = {}


local function httpRequest(s, sitename)
	local request = string.format("GET / HTTP/1.1\r\nUser-Agent: schedlua (linux-gnu)\r\nAccept: */*\r\nHost: %s\r\nConnection: close\r\n\r\n", sitename);
	return s:write(request, #request);
end

local function httpResponse(s)
	local BUFSIZ = 512;
	local buffer = ffi.new("char[512+1]");
	local bytesRead = 0
	local err = nil;
	local cumulative = 0

	repeat
		bytesRead, err = s:read(buffer, BUFSIZ);

		if bytesRead then
			cumulative = cumulative + bytesRead;
		else
			print("read, error: ", err)
			break;
		end
	until bytesRead < 1

	return cumulative;
end


local function siteGET(sitename)
	print("siteGET, BEGIN: ", sitename);

	local s = AsyncSocket();

	local success, err = s:connect(sitename, 80);  

	if success then
		httpRequest(s, sitename);
		httpResponse(s);
	else
		print("connect, error: ", err, sitename);
	end

	s:close();

	print("siteGET, FINISHED: ", sitename)
end


local function allProbesFinished()
	for idx, t in ipairs(taskList) do
		if t:getStatus() ~= "dead" then
			return false;
		end
	end

	return true;
end

local function main()
	for count=1,20 do
		table.insert(taskList, Kernel:spawn(siteGET, sites[math.random(#sites)]))
		Kernel:yield();
	end

	when(allProbesFinished, halt);

--[[
	while true
		if allProbesFinished() then
			halt();
			break;
		end
		yield();
	end
--]]
end

run(main)
