-- asyncio.lua

local ffi = require("ffi")
local bit = require("bit")
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift

local coreio = require("schedlua.windows.core_io_l1_1_1")



local	EventQuanta = 10;
local	ContinueRunning = true;
local	EPollSet = epoll.epollset();
local	MaxEvents = 100;		-- number of events we'll ask per quanta

local	READ = 1;
local	WRITE = 2;
local	CONNECT = 3;


local Events = ffi.new("struct epoll_event[?]", self.MaxEvents);


local function sigNameFromEvent(event, title)
	title = title or "";
	local fdesc = ffi.cast("filedesc *", event.data.ptr);
	--print("sigNameFromEvent, fdesc: ", fdesc)
	local fd = fdesc.fd;
	--print("  fd: ", fd);

	local str = "waitforio-"..fd;
	
	return str;
end


local function setEventQuanta(quanta)
	self.EventQuanta = quanta;
end

local function getNextOperationId()
	OperationId = OperationId + 1;
	return OperationId;
end

local function watchForIOEvents(fdesc, event)
	return self.EPollSet:add(fdesc.fd, event);
end

local function waitForIOEvent(fdesc, event, title)
	local success, err = EPollSet:modify(fdesc.fd, event);
	local sigName = sigNameFromEvent(event, title);

--print("\nAsyncIO.waitForIOEvent(), waiting for: ", sigName)

	success, err = waitForSignal(sigName);

	return success, err;
end


-- The watchdog() routine is the regular task that will
-- always be calling epoll_wait when it gets a chance
-- and signaling the appropriate tasks when they have events
local function watchdog()
	while ContinueRunning do
		local available, err = EPollSet:wait(Events, MaxEvents, EventQuanta);
--print("+=+=+= AsyncIO.watchdog: ", available, err)


		if available then
			if available > 0 then
--print("+=+=+= AsyncIO.watchdog: ", available)
			    for idx=0,available-1 do
			    	local ptr = ffi.cast("struct epoll_event *", ffi.cast("char *", self.Events)+ffi.sizeof("struct epoll_event")*idx);
			    	--print("watchdog, ptr.data.ptr: ", ptr, ptr.data.ptr);
				    local sigName = sigNameFromEvent(ptr);
--print(string.format("AsyncIO.watchdog(), signaling: '%s'  Events: 0x%x", sigName,  self.Events[idx].events))
				    signalAll(sigName, Events[idx].events);
			    end
			else
				--print("NO EVENTS AVAILABLE")
			end
		else 
			print("AsyncIO.watchdog, error from EPollSet:wait(): ", available, err)
		end

		yield();
	end
end


local function globalize(tbl)
	tbl = tbl or _G

	tbl["waitForIOEvent"] = waitForIOEvent;
	tbl["watchForIOEvents"] = watchForIOEvents;

	return tbl;
end

globalize()

AsyncIO = spawn(watchdog)

return AsyncIO
