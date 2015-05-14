package.path = package.path.."';../?.lua"
--test_linux_net.lua
--[[
	Simple networking test case.
	Implement a client to the daytime service (port 13)
	Make a basic TCP connection, read data, finish
--]]
local ffi = require("ffi")
local bit = require("bit")
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift

local net = require("linux_net"){exportglobal=true}


local server_address = "127.0.0.1"
local server_port = 13;


local function main()
	local s = net.bsdsocket(SOCK_STREAM);

	local sa, err = net.sockaddr_in(server_address, server_port);
	local success, err =  net.connect(s, sa)
	if not success then
		print("connect, error", err);
		return false, err;
	end


	local BUFSIZ = 512;
	local buffer = ffi.new("char[512+1]");
	local bytesRead
	
	repeat
		bytesRead, err = s:read(buffer, BUFSIZ);
		if not bytesRead then
			print("read, error: ", err)
			return false, err;
		end

		local str = ffi.string(buffer, bytesRead);
		io.write(str);
	until bytesRead < 1
end

main()
