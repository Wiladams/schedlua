
if Kernel_Included then
	return Kernel;
end

local Kernel_Included = true;

local Scheduler = require("scheduler")()
local Task = require("task")
local Queue = require("queue")
local Functor = require("functor")

local Kernel = {
	ContinueRunning = true;
	TaskID = 0;
	Scheduler = Scheduler;
	TasksSuspendedForSignal = {};
}


function Kernel.getNewTaskID(self)
	self.TaskID = self.TaskID + 1;
	return self.TaskID;
end

function Kernel.getCurrentTaskID(self)
	return self.Scheduler:getCurrentFiber().TaskID;
end

function Kernel.spawn(self, func, ...)
	local task = Task(func, ...)
	task.TaskID = self:getNewTaskID();
	self.Scheduler:scheduleTask(task, {...});
	
	return task;
end

function Kernel.suspend(self, ...)
	self.Scheduler:suspendCurrentFiber();
	return self:yield(...)
end

function Kernel.yield(self, ...)
	return self.Scheduler:yield();
	--return coroutine.yield(...);
end

--[[
	Signal Related Functions

	Signaling is a fundamental building block for other forms
	of yielding in the kernel.  These routines are here because
	of their building block nature.  A task can end up waiting on 
	many different forms of signals, such as time, a predicate, IO,
	or just a general event or coordination barrier.

	Signaling could also be implemented as a separable plugin task,
	but it's so fundamental to this kernel that it makes more sense
	to stick in in here.
--]]
function Kernel.signalOne(self, eventName)
	if not self.TasksSuspendedForSignal[eventName] then
		return false, "event not registered", eventName
	end

	local nTasks = #self.TasksSuspendedForSignal[eventName]
	if nTasks < 1 then
		return false, "no tasks waiting for event"
	end

	local suspended = self.TasksSuspendedForSignal[eventName][1];
	--print("suspended: ", suspended, suspended.routine);

	self.Scheduler:scheduleTask(suspended);
	table.remove(self.TasksSuspendedForSignal[eventName], 1);
	-- TODO
	-- if the table for the signal now has zero entries
	-- we can probably remove the table to free up some space
	-- otherwise, we'll have an increasing amount of garbage for
	-- one off signals, especially in the case of high frequency IO

	return true;
end

function Kernel.signalAll(self, eventName)
	if not self.TasksSuspendedForSignal[eventName] then
		return false, "event not registered"
	end

	local nTasks = #self.TasksSuspendedForSignal[eventName]
	if nTasks < 1 then
		return false, "no tasks waiting for event"
	end

	for i=1,nTasks do
		self.Scheduler:scheduleTask(self.TasksSuspendedForSignal[eventName][1]);
		table.remove(self.TasksSuspendedForSignal[eventName], 1);
	end

	return true;
end

function Kernel.waitForSignal(self, eventName)
	local currentFiber = self.Scheduler:getCurrentFiber();

	--print("waitForEvent.yield: ", eventName, currentFiber)

	if currentFiber == nil then
		return false, "not currently in a running task"
	end

	-- add the fiber to the list of suspended tasks
	if not self.TasksSuspendedForSignal[eventName] then
		self.TasksSuspendedForSignal[eventName] = {}
	end

	table.insert(self.TasksSuspendedForSignal[eventName], currentFiber);

	return self:suspend()
end

function Kernel.onSignal(self, func, eventName)
	local function closure()
		self:waitForSignal(eventName)
		func();
	end

	return self:spawn(closure)
end

--[[
	Primary Activation
--]]


function Kernel.run(self, func, ...)

	if func ~= nil then
		self:spawn(func, ...)
	end

	-- This is a high CPU load event loop
	-- ideally, we'd be able to figure out when we could
	-- actually just sleep for a bit, in an OS sense
	-- this would tie the kernel to some OS specific notion
	-- of notification, based on either IO or time
	-- it could be as easy as a microsecond sleep, or yield
	while (self.ContinueRunning) do
		self.Scheduler:step();
		
		-- automatically stop the kernel if there are no tasks ready to run
		-- and no tasks suspended waiting for a signal
		if self.Scheduler:tasksPending() < 1 then
			-- TODO - check the length of the dictionaries
			-- very expensive
			--if self.TasksSuspendedForSignal:length() < 1 then
			--	break;
			--end
			break;
		end
	end
end

function Kernel.halt(self)
	self.ContinueRunning = false;
end

-- set a metatable on the Kernel table so that all the functions
-- can be put into the global namespace by simply calling Kernel()
--
-- we don't make them global automatically, because not every application
-- will want that behavior.  This way, the app writer can decide if they 
-- want the global namespace polluted or not.
function Kernel.globalize()
	halt = Functor(Kernel.halt, Kernel);
    onSignal = Functor(Kernel.onSignal, Kernel);

    run = Functor(Kernel.run, Kernel);

    signalAll = Functor(Kernel.signalAll, Kernel);
    signalOne = Functor(Kernel.signalOne, Kernel);

    spawn = Functor(Kernel.spawn, Kernel);
    suspend = Functor(Kernel.suspend, Kernel);

    waitForSignal = Functor(Kernel.waitForSignal, Kernel);

    yield = Functor(Kernel.yield, Kernel);
end

setmetatable(Kernel, {
    __call = function(self, params)
    	params = params or {
    		makeGlobal = false;
    		scheduler = Scheduler;
    	}

    	if params.makeGlobal then
    		self:globalize();
    	end
    	if params.scheduler then 
    		self.Scheduler = params.scheduler;
    	end

    	return self;
    end,
})

return Kernel();
