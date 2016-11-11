local ffi = require("ffi")
local bit = require("bit")
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift

local net = require("schedlua.linux.linux_net")
local epoll = require("schedlua.linux.epollio");
local errnos = require("schedlua.linux.linux_errno").errnos
local lookupsite = require("schedlua.linux.lookupsite")


--[[
    Async IO Specific
]]
local EventQuanta = 10;
local MaxEvents = 100;		-- number of events we'll ask per quanta
local Events = ffi.new("struct epoll_event[?]", MaxEvents);
local PollSet = epoll.epollset();


local IO_READ = 1;
local IO_WRITE = 2;
local IO_CONNECT = 3;


local function sigNameFromFileDescriptor(fd)
	return "waitforio-"..fd
end

---[[
local function sigNameFromEvent(event, title)
	title = title or "";
	local fdesc = ffi.cast("filedesc *", event.data.ptr);
	--print("sigNameFromEvent, fdesc: ", fdesc)
	local fd = fdesc.fd;
	--print("  fd: ", fd);

	return sigNameFromFileDescriptor(fdesc.fd);
end
--]]

local function setEventQuanta(quanta)
	EventQuanta = quanta;
end


local function watchForIOEvents(fd, event)
	return PollSet:add(fd, event);
end

-- This function allows us to wait for a specific IO event
--
local function waitForIOEvent(fdesc, event, title)
--print("waitForIOEvent: ", fdesc.fd, event, title)
	local success, err = PollSet:modify(fdesc.fd, event);

	local sigName = sigNameFromEvent(event, title);
print("waitForIOEvent, modify, sigName: ", success, err, sigName)
	success, err = waitForSignal(sigName);
print("waitForIOEvent, wait: ", success, err)

	return success, err;
end



local function ioAvailable()
	local success, events = PollSet:wait(Events, MaxEvents);

print("ioAvailable, after wait: ", success, events, Events)

    if not success then return false end

    return success, events;
end

local function signalIOTasks(available, events)
    print("signalIOTasks: ", available, events)

    for idx=0,available-1 do
	    --local event = ffi.cast("struct epoll_event *", ffi.cast("char *", Events)+ffi.sizeof("struct epoll_event")*idx);
		--print("signalIOTasks, ptr.data.ptr: ", ptr, ptr.data.ptr);
		local sigName = sigNameFromFileDescriptor(Events[idx].data.fd);
        print(string.format("signalIOTasks(), signaling: '%s'", sigName))
		signalAll(sigName, Events[idx].events);
	end
end



--[[
    Create something that represents a socket in the underlying
    operating system.
--]]
local NativeSocket = {}
setmetatable(NativeSocket, {
	__call = function(self, ...)
		return self:create(...);
	end,
});

local NativeSocket_mt = {
	__index = NativeSocket;
}


function NativeSocket:init(sock, kind, family, flags)
    local obj = {
        kind = kind;
        family = family;
        flags = flags;

        fdesc = net.filedesc(sock);
    }


    obj.fdesc:setNonBlocking(true);

    obj.WatchdogEvent = ffi.new("struct epoll_event")
    obj.WatchdogEvent.data.ptr = obj.fdesc;
    obj.WatchdogEvent.events = bor(epoll.EPOLLOUT,epoll.EPOLLIN, epoll.EPOLLRDHUP, epoll.EPOLLERR, epoll.EPOLLET);

    watchForIOEvents(obj.fdesc.fd, obj.WatchdogEvent);

    obj.ConnectEvent = ffi.new("struct epoll_event")
    obj.ConnectEvent.data.ptr = obj.fdesc;
    obj.ConnectEvent.events = bor(epoll.EPOLLOUT,epoll.EPOLLRDHUP, epoll.EPOLLERR, epoll.EPOLLET);

    obj.ReadEvent = ffi.new("struct epoll_event")
    obj.ReadEvent.data.ptr = obj.fdesc;
    obj.ReadEvent.events = bor(epoll.EPOLLIN, epoll.EPOLLERR); 

    obj.WriteEvent = ffi.new("struct epoll_event")
    obj.WriteEvent.data.ptr = obj.fdesc;
    obj.WriteEvent.data.fd = obj.fdesc.fd;
    obj.WriteEvent.events = bor(epoll.EPOLLOUT, epoll.EPOLLERR); 

    setmetatable(obj, NativeSocket_mt)

    return obj;
end

function NativeSocket:create(kind, flags, family)
    kind = kind or net.SOCK_STREAM;
    family = family or net.AF_INET
    flags = flags or 0;

    local sock = ffi.C.socket(family, kind, flags);

--print("NativeSocket:create, sock: ", sock)

    if sock < 0 then
        return nil, ffi.errno();
    end

    return self:init(sock, kind, family, flags)
end




function NativeSocket.setSocketOption(self, optname, on, level)
    local feature_on = ffi.new("int[1]")
    if on then feature_on[0] = 1; end
    level = level or net.SOL_SOCKET 

    local ret = ffi.C.setsockopt(self.fdesc.fd, level, optname, feature_on, ffi.sizeof("int"))
    
    return ret == 0;
end

function NativeSocket.setNonBlocking(self, on)
    return self.fdesc:setNonBlocking(on);
end

function NativeSocket.setUseKeepAlive(self, on)
    return setSocketOption(self, net.SO_KEEPALIVE, on);
end

function NativeSocket.setReuseAddress(self, on)
    return setSocketOption(self, net.SO_REUSEADDR, on);
end

function NativeSocket.getLastError(self)
    local retVal = ffi.new("int[1]")
    local retValLen = ffi.new("int[1]", ffi.sizeof("int"))

    local ret = getSocketOption(self, net.SO_ERROR, retVal, retValLen)

    return retVal[0];
end

function NativeSocket.connect(self, servername, port)
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
    local success, err = waitForIOEvent(self.fdesc, self.ConnectEvent);

    return success, err;
end

function NativeSocket.read(self, buff, bufflen)
    
    local success, err = waitForIOEvent(self.fdesc, self.ReadEvent);
    
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

function NativeSocket.write(self, buff, bufflen)

  local success, err = waitForIOEvent(self.fdesc, self.WriteEvent);
  print(string.format("async_write, after wait: 0x%x %s", success, tostring(err)))
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

function NativeSocket.close(self)
    self.fdesc:close();
end


-- Start off the iotask watchdog
whenever(ioAvailable, signalIOTasks)

return NativeSocket

