--lookupsite.lua
package.path = package.path..";../?.lua"

local ffi = require("ffi")
local net = require("linux_net")
local sites = require("sites")

--[[
struct addrinfo {
  int     ai_flags;          // AI_PASSIVE, AI_CANONNAME, ...
  int     ai_family;         // AF_xxx
  int     ai_socktype;       // SOCK_xxx
  int     ai_protocol;       // 0 (auto) or IPPROTO_TCP, IPPROTO_UDP 

  socklen_t  ai_addrlen;     // length of ai_addr
  struct sockaddr  *ai_addr; // binary address
  char   *ai_canonname;      // canonical name for nodename
  struct addrinfo  *ai_next; // next structure in linked list
};
--]]

local function lookupsite(nodename)
	print("==== lookupsite: ", nodename)

	local servname = "http"
	local res = ffi.new("struct addrinfo * [1]")
	local hints = ffi.new("struct addrinfo")

	hints.ai_flags = net.AI_CANONNAME;
	hints.ai_family = net.AF_UNSPEC;
	hints.ai_socktype = net.SOCK_STREAM;

	local ret = ffi.C.getaddrinfo(nodename, servname, hints, res);
print("getaddrinfo: ", ret)
	if ret ~= 0 then
		return false, ret;
	end

	local ptr = res[0];
	
	local sa = ffi.new("struct sockaddr_in")

	print(string.format("-- family: %d  socktype: %d  proto: %d", 
			ptr.ai_family, ptr.ai_socktype, ptr.ai_protocol));
	if ptr.ai_canonname ~= nil then
			print("  canonname: ", ffi.string(ptr.ai_canonname))
	end	

	--print("  ai.addr: ", ptr.ai_addr, ptr.ai_addrlen);

	ffi.copy(sa, ptr.ai_addr, ffi.sizeof(sa))

	ffi.C.freeaddrinfo(res[0]);

	return sa, ffi.sizeof(sa)
end


for idx=1,5 do
	print(lookupsite(sites[idx]))
end


--print(lookupsite(nil))