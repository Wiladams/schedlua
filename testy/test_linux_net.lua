--test_linux_net.lua
local ffi = require("ffi")
local bit = require("bit")
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift

local net = require("linux_net"){importglobal=true}

local BUFSIZ = 512;



local function main()
	local sa = ffi.new("struct sockaddr_in");
	local buffer = ffi.new("char[512+1]");

	local s = ffi.C.socket(AF_INET, SOCK_STREAM, 0);
	if s < 0 then
		error("failed to create socket", ffi.errno());
	end
--print("SOCKET: ", s)
	inp = ffi.new("struct in_addr")
	ret = ffi.C.inet_aton ("127.0.0.1", inp);
--print("inet_aton: ", ret);

	sa.sin_family = AF_INET;
	sa.sin_port = htons(13);
	sa.sin_addr.s_addr = inp.s_addr;
	local ret = tonumber(ffi.C.connect(s, ffi.cast("struct sockaddr *", sa), ffi.sizeof(sa)))
--print("CONNECT: ", ret);
	if ret < 0 then
		print("connect, error", ffi.errno());
		ffi.C.close(s);
		return false, ffi.errno();
	end

	local bytes
	repeat
		bytes = tonumber(ffi.C.read(s, buffer, BUFSIZ));
		--print("BYTES: ", bytes)
		if bytes < 1 then
			if bytes == 0 then
				return true, 0;
			end

			print("recv, error: ", ffi.errno())
			return false, ffi.errno();
		end
		local str = ffi.string(buffer, bytes);
		io.write(str);
	until bytes < 1
end

main()
