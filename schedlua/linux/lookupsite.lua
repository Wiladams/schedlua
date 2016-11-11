local ffi = require("ffi")
local net = require("schedlua.net")

local function lookupsite(nodename, servname)
    --local servname = nil; -- "http"
    local res = ffi.new("struct addrinfo * [1]")
    local hints = ffi.new("struct addrinfo")

    --hints.ai_flags = net.AI_CANONNAME;
    hints.ai_family = net.AF_INET;
    hints.ai_socktype = net.SOCK_STREAM;

    local ret = ffi.C.getaddrinfo(nodename, servname, hints, res);
    --print("getaddrinfo: ", ret)
    if ret ~= 0 then
        return false, ret;
    end

  
    local sa = ffi.new("struct sockaddr")
    local addrlen = res[0].ai_addrlen;

    ffi.copy(sa, res[0].ai_addr, res[0].ai_addrlen)

    ffi.C.freeaddrinfo(res[0]);

    return sa, addrlen
end

return lookupsite
