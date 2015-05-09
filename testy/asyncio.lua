-- asyncio.lua
package.path = package.path..";../?.lua"

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
	MaxEvents = 10;		-- number of events we'll ask per quanta
}

setmetatable(AsyncIO, {
	__call = function(self, params)
		params = params or {}
		self.Kernel = params.Kernel
		self.Events = ffi.new("struct epoll_event[?]", self.MaxEvents);

		if params.exportglobal then
			self:globalize();
		end
		
		if self.Kernel and params.AutoStart then
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
	event.events = bor(EPOLLOUT,EPOLLIN, EPOLLRDHUP, EPOLLERR, EPOLLET); -- EPOLLET

	return self.EPollSet:add(fd, event);
end

function AsyncIO.waitForIOEvent(self, fd, event)
--print("== waitForIO.yield: BEGIN: ", arch.pointerToString(overlapped));
	-- assuming the fd has already been added to 
	-- the epoll set, modify it to match the new
	-- event
	local success, err = self.EPollSet:modify(fd, event);
	--print("ASyncIO.waitForIOEvent(), modify: ", success, err)
	-- create a signal which the current task can be put 
	-- to watch

	-- This assumes that the watchdog will catch when the event
	-- occurs, and fire off the signal	
	local sigName = "waitforio-"..fd;

	success, err = self.Kernel:waitForSignal(sigName);
	--print("ASyncIO.waitForIOEvent(), after waitforsignal: ", sigName, success, err)

	return success, err;
end




function AsyncIO.watchdog(self)
	while self.ContinueRunning do
		local success, err = self.EPollSet:wait(self.Events, self.MaxEvents, self.EventQuanta);

		--print("watchdog waited: ", success, err);

		if not success then 
			return false, err;
		end

		-- we got some number of events, so process them
		for idx=0,success-1 do
				-- create signal name
				local sigName = "waitforio-"..self.Events[idx].data.fd;

				-- signal anyone waiting for it
				self.Kernel:signalAll(sigName);
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
