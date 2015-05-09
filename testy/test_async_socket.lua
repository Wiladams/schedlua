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



local function main()
	local s = net.AsyncSocket();

	success, err = s:connect("127.0.0.1", 13);

	if not success then
		print("connect, error: ", err);
		return false, err
	end

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

Kernel:run(main)
