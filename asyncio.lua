-- asyncio.lua

if AsyncIO_Included then
	return AsyncIO;
end

local AsyncIO_Included = true;

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




function AsyncIO.setEventQuanta(self, quanta)
	self.EventQuanta = quanta;
end

function AsyncIO.getNextOperationId(self)
	self.OperationId = self.OperationId + 1;
	return self.OperationId;
end

function AsyncIO.watchForIOEvents(self, fd)
	local event = ffi.new("struct epoll_event")
	event.data.fd = fd;
	event.events = bor(epoll.EPOLLOUT,epoll.EPOLLIN, epoll.EPOLLRDHUP, epoll.EPOLLERR, epoll.EPOLLET);

	return self.EPollSet:add(fd, event);
end

function AsyncIO.waitForIOEvent(self, fd, event)
	local success, err = self.EPollSet:modify(fd, event);
	local sigName = "waitforio-"..fd;

	success, err = self.Kernel:waitForSignal(sigName);

	return success, err;
end


-- The watchdog() routine is the regular task that will
-- always be calling epoll_wait when it gets a chance
-- and signaling the appropriate tasks when they have events
function AsyncIO.watchdog(self)
	while self.ContinueRunning do
		local success, err = self.EPollSet:wait(self.Events, self.MaxEvents, self.EventQuanta);

		if not success then 
			return false, err;
		end

		for idx=0,success-1 do
				-- create signal name
				local sigName = "waitforio-"..self.Events[idx].data.fd;
				self.Kernel:signalAll(sigName, self.Events[idx].events);
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
