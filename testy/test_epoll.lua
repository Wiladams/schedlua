--test_epoll.lua
local epoll = require("epoll")()

local function main()
	local set1 = epollset();
	print(set1)

	if not set1 then return false end

	-- Create a file descriptor that we can put into 
	-- the epoll set.
	local fd = select(127.0.0.1)

	local evdata = ffi.new("struct epoll_event")
	evdata.events = 1;
	evdata.data.fd = fd;

	set1:add(fd, evdata)
end


main()
