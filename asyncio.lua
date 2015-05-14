-- asyncio.lua

local ffi = require("ffi")
local bit = require("bit")
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift


local Functor = require("functor")
local epoll = require("epoll");



local AsyncIO = {
	EventQuanta = 10;
	ContinueRunning = true;
	EPollSet = epoll.epollset();
	MaxEvents = 100;		-- number of events we'll ask per quanta

	READ = 1;
	WRITE = 2;
	CONNECT = 3;
}

setmetatable(AsyncIO, {
	__call = function(self, params)
		params = params or {}
		self.Kernel = params.Kernel
		self.Events = ffi.new("struct epoll_event[?]", self.MaxEvents);

		if params.exportglobal then
			self:globalize();
		end
		
		if self.Kernel and params.AutoStart ~= false then
			self.Kernel:spawn(Functor(AsyncIO.watchdog, AsyncIO))
		end

		return self;
	end,
})


local function sigNameFromEvent(event, title)
	title = title or "";
	local fdesc = ffi.cast("filedesc *", event.data.ptr);
	--print("sigNameFromEvent, fdesc: ", fdesc)
	local fd = fdesc.fd;
	--print("  fd: ", fd);

	local str = "waitforio-"..fd;
	
	return str;
end


function AsyncIO.setEventQuanta(self, quanta)
	self.EventQuanta = quanta;
end

function AsyncIO.getNextOperationId(self)
	self.OperationId = self.OperationId + 1;
	return self.OperationId;
end

function AsyncIO.watchForIOEvents(self, fdesc, event)
	return self.EPollSet:add(fdesc.fd, event);
end

function AsyncIO.waitForIOEvent(self, fdesc, event, title)
	local success, err = self.EPollSet:modify(fdesc.fd, event);
	local sigName = sigNameFromEvent(event, title);

--print("\nAsyncIO.waitForIOEvent(), waiting for: ", sigName)

	success, err = self.Kernel:waitForSignal(sigName);

	return success, err;
end


-- The watchdog() routine is the regular task that will
-- always be calling epoll_wait when it gets a chance
-- and signaling the appropriate tasks when they have events
function AsyncIO.watchdog(self)
	while self.ContinueRunning do
		local available, err = self.EPollSet:wait(self.Events, self.MaxEvents, self.EventQuanta);
--print("+=+=+= AsyncIO.watchdog: ", available, err)


		if available then
			if available > 0 then
--print("+=+=+= AsyncIO.watchdog: ", available)
			    for idx=0,available-1 do
			    	local ptr = ffi.cast("struct epoll_event *", ffi.cast("char *", self.Events)+ffi.sizeof("struct epoll_event")*idx);
			    	--print("watchdog, ptr.data.ptr: ", ptr, ptr.data.ptr);
				    local sigName = sigNameFromEvent(ptr);
--print(string.format("AsyncIO.watchdog(), signaling: '%s'  Events: 0x%x", sigName,  self.Events[idx].events))
				    self.Kernel:signalAll(sigName, self.Events[idx].events);
			    end
			else
				--print("NO EVENTS AVAILABLE")
			end
		else 
			print("AsyncIO.watchdog, error from EPollSet:wait(): ", available, err)
		end

		self.Kernel:yield();
	end
end


function AsyncIO.globalize(self)
	_G["waitForIOEvent"] = Functor(AsyncIO.waitForIOEvent, AsyncIO);
	_G["watchForIOEvents"] = Functor(AsyncIO.watchForIOEvents, AsyncIO);

	return self;
end

return AsyncIO
