local ffi = require("ffi")
local bit = require("bit")
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift

local net = require("linux_net")
local epoll = require("epoll")
local asyncio = require("asyncio")
local errnos = require("linux_errno").errnos


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

local AsyncSocket = {}
setmetatable(AsyncSocket, {
    __call = function(self, ...)
        return self:new(...);
    end,
})

local AsyncSocket_mt = {
    __index = AsyncSocket;
}

function AsyncSocket.init(self, sock)
    local obj = {
        fdesc = net.filedesc(sock);
    }
    setmetatable(obj, AsyncSocket_mt);

    obj.fdesc:setNonBlocking(true);

    obj.WatchdogEvent = ffi.new("struct epoll_event")
    obj.WatchdogEvent.data.ptr = obj.fdesc;
    obj.WatchdogEvent.events = bor(epoll.EPOLLOUT,epoll.EPOLLIN, epoll.EPOLLRDHUP, epoll.EPOLLERR, epoll.EPOLLET);

    asyncio:watchForIOEvents(obj.fdesc, obj.WatchdogEvent);

    obj.ConnectEvent = ffi.new("struct epoll_event")
    obj.ConnectEvent.data.ptr = obj.fdesc;
    obj.ConnectEvent.events = bor(epoll.EPOLLOUT,epoll.EPOLLRDHUP, epoll.EPOLLERR, epoll.EPOLLET);

    obj.ReadEvent = ffi.new("struct epoll_event")
    obj.ReadEvent.data.ptr = obj.fdesc;
    obj.ReadEvent.events = bor(epoll.EPOLLIN, epoll.EPOLLERR); 

    obj.WriteEvent = ffi.new("struct epoll_event")
    obj.WriteEvent.data.ptr = obj.fdesc;
    obj.WriteEvent.events = bor(epoll.EPOLLOUT, epoll.EPOLLERR); 

    return obj;
end

function AsyncSocket.new(self, kind, flags, family)
    kind = kind or net.SOCK_STREAM;
    family = family or net.AF_INET
    flags = flags or 0;
    local s = ffi.C.socket(family, kind, flags);
    if s < 0 then
        return nil, ffi.errno();
    end

    return self:init(s);
end

function AsyncSocket.setSocketOption(self, optname, on, level)
    local feature_on = ffi.new("int[1]")
    if on then feature_on[0] = 1; end
    level = level or net.SOL_SOCKET 

    local ret = ffi.C.setsockopt(self.fdesc.fd, level, optname, feature_on, ffi.sizeof("int"))
    return ret == 0;
end

function AsyncSocket.setNonBlocking(self, on)
    return self.fdesc:setNonBlocking(on);
end

function AsyncSocket.setUseKeepAlive(self, on)
    return self:setSocketOption(net.SO_KEEPALIVE, on);
end

function AsyncSocket.setReuseAddress(self, on)
    return self:setSocketOption(net.SO_REUSEADDR, on);
end

function AsyncSocket.getLastError(self)
    local retVal = ffi.new("int[1]")
    local retValLen = ffi.new("int[1]", ffi.sizeof("int"))

    local ret = self:getSocketOption(net.SO_ERROR, retVal, retValLen)

    return retVal[0];
end

function AsyncSocket.connect(self, servername, port)
    local sa, size = lookupsite(servername);
    if not sa then 
        return false, size;
    end
    ffi.cast("struct sockaddr_in *", sa):setPort(port);

    local ret = tonumber(ffi.C.connect(self.fdesc.fd, sa, size));

    local err = ffi.errno();
    if ret ~= 0 then
        if  err ~= errnos.EINPROGRESS then
            return false, err;
        end
    end


    -- now wait for the socket to be writable
    local success, err = asyncio:waitForIOEvent(self.fdesc, self.ConnectEvent);

    return success, err;
end

function AsyncSocket.read(self, buff, bufflen)
    
    local success, err = asyncio:waitForIOEvent(self.fdesc, self.ReadEvent);
    
    --print(string.format("AsyncSocket.read(), after wait: 0x%x %s", success, tostring(err)))

   if not success then
        print("AsyncSocket.read(), FAILED WAITING: ", string.format("0x%x",err))
        return false, err;
    end

 
    local bytesRead = 0;

    if band(success, epoll.EPOLLIN) > 0 then
        bytesRead, err = self.fdesc:read(buff, bufflen);
        --print("async_read(), bytes read: ", bytesRead, err)
    end
    
    return bytesRead, err;
end

function AsyncSocket.write(self, buff, bufflen)

  local success, err = asyncio:waitForIOEvent(self.fdesc, self.WriteEvent);
  --print(string.format("async_write, after wait: 0x%x %s", success, tostring(err)))
  if not success then
    return false, err;
  end
  
  local bytes = 0;

  if band(success, epoll.EPOLLOUT) > 0 then
    bytes, err = self.fdesc:write(buff, bufflen);
    --print("async_write(), bytes: ", bytes, err)
  end

  return bytes, err;
end

function AsyncSocket.close(self)
    self.fdesc:close();
end

return AsyncSocket
