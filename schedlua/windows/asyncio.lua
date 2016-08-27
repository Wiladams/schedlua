-- waitForIO.lua

local ffi = require("ffi")
local iocompletionset = require("IOCompletionPort");
local arch = require("arch")


local	EventQuanta = 10;
local	ContinueRunning = true;
local	PollSet = iopoll();
local	MaxEvents = 100;		-- number of events we'll ask per quanta

local	READ = 1;
local	WRITE = 2;
local	CONNECT = 3;







function waitForIO.init(self, scheduler)
	-- print("waitForIO.init, MessageQuanta: ", self.MessageQuanta)
	
	local obj = {
		IOEventQueue = IOCompletionPort:create();
		FibersAwaitingEvent = {};
		EventFibers = {};

		MessageQuanta = self.MessageQuanta;		-- milliseconds
		OperationId = 0;
	}
	setmetatable(obj, waitForIO_mt)

	return obj;
end

function waitForIO.create(self, scheduler)
	scheduler = scheduler or self.Scheduler

	if not scheduler then
		return nil, "no scheduler specified"
	end

	return self:init(scheduler)
end

function waitForIO.setMessageQuanta(self, quanta)
	self.MessageQuanta = quanta;
end

function waitForIO.setScheduler(self, scheduler)
	self.Scheduler = scheduler;
end

function waitForIO.tasksArePending(self)
	local fibersawaitio = false;

	for fiber in pairs(self.FibersAwaitingEvent) do
		fibersawaitio = true;
		break;
	end

	return fibersawaitio
end


local function getNextOperationId()
	OperationId = OperationId + 1;
	return OperationId;
end

local function watchForIOEvents(handle, param)
	--print("waitForIO.observeIOEvent, adding: ", handle, param)

	return PollSet:add(handle, param);
end

--[[
function waitForIO.yield(self, socket, overlapped)
--print("== waitForIO.yield: BEGIN: ", arch.pointerToString(overlapped));

	local currentFiber = self.Scheduler:getCurrentFiber()

	if not currentFiber then
		print("waitForIO.yield:  NO CURRENT FIBER");
		return nil, "not currently running within a task"
	end

	-- Track the task based on the overlapped structure
	self.EventFibers[arch.pointerToString(overlapped)] = currentFiber;
	self.FibersAwaitingEvent[currentFiber] = true;
	
	return self.Scheduler:suspend()
end
--]]


local function processIOEvent(key, numbytes, overlapped)
--print("waitForIO.processIOEvent: ", key, numbytes, arch.pointerToString(overlapped))

	local ovl = ffi.cast("IOOverlapped *", overlapped);

	ovl.bytestransferred = numbytes;

	-- Find the task that is waiting for this IO event
	local fiber = self.EventFibers[arch.pointerToString(overlapped)]

--print("waitForIO: fiber wiating: ", fiber)

	if not fiber then
		print("waitForIO: No fiber waiting for IO Completion")
		return false, "waitForIO.processIOEvent,NO FIBER WAITING FOR IO EVENT: "
	end

	-- remove the task from the list of tasks that are
	-- waiting for an IO event
	self.FibersAwaitingEvent[fiber] = nil;

	-- remove the fiber from the index based on the
	-- overlapped structure
	self.EventFibers[arch.pointerToString(overlapped)] = nil;
--print("waitForIO.processIOEvent, before rescheduler:", key, numbytes, overlapped)
	local task = self.Scheduler:scheduleTask(fiber, {key, numbytes, overlapped});
--print("after reschedule: ", task.state)

	return true;
end


local function watchdog()
	while true do
		-- Check to see if there are any IO Events to deal with
		--local key, numbytes, overlapped = self.IOEventQueue:dequeue(self.MessageQuanta);
		local param1, param2, param3, param4, param5 = self.IOEventQueue:dequeue(self.MessageQuanta);

--print("waitForIO.step: ", param1, param2)

		local key, bytes, ovl

		-- First check to see if we've got a timeout
		-- if so, then just return immediately
		if not param1 then
			if param2 == WAIT_TIMEOUT then
				return true;
			end
		
			-- other errors that can occur at this point
			-- could either be iocp errors, or they could
			-- be socket specific errors
			-- If the error is ERROR_NETNAME_DELETED
			-- a socket has closed, so do something about it?
--[[
		if param2 == ERROR_NETNAME_DELETED then
			print("Processor.stepIOEvents(), ERROR_NETNAME_DELETED: ", param3);
		else
			print("Processor.stepIOEvents(), ERROR: ", param3, param2);
		end
--]]
			key = param3;
			bytes = param4;
			ovl = param5; 
		else
			key = param1;
			bytes = param2;
			ovl = param3;
		end

		local status, err = processIOEvent(key, bytes, ovl);

		yield()
	end
end

function watchdog(self)
	while true do
		local status, err = self:step();
		--print("waitForIO.start, status, err: ", status, err)

		yield();
	end
end


return waitForIO
