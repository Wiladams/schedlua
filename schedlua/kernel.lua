--kernel.lua
-- kernel is a singleton, so return
-- single instance if we've already been
-- through this code
--print("== KERNEL INCLUDED ==")

local Scheduler = require("schedlua.scheduler")
local Task = require("schedlua.task")
--local Queue = require("queue")
local Functor = require("schedlua.functor")

local Kernel = {
	ContinueRunning = true;
	TaskID = 0;
	Scheduler = Scheduler();
	TasksSuspendedForSignal = {};
}

setmetatable(Kernel, {
    __call = function(self, keeplocal)
    	params = params or {}
    	params.Scheduler = params.Scheduler or self.Scheduler
    	
    	if not keeplocal then
    		self:globalize();
    	end

    	self.Scheduler = params.Scheduler;

    	return self;
    end,
})

function Kernel.getNewTaskID(self)
	self.TaskID = self.TaskID + 1;
	return self.TaskID;
end

function Kernel.getCurrentTaskID(self)
	return self:getCurrentTask().TaskID;
end

function Kernel.getCurrentTask(self)
	return self.Scheduler:getCurrentTask();
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
end


function Kernel.signalOne(self, eventName, ...)
	if not self.TasksSuspendedForSignal[eventName] then
		return false, "event not registered", eventName
	end

	local nTasks = #self.TasksSuspendedForSignal[eventName]
	if nTasks < 1 then
		return false, "no tasks waiting for event"
	end

	local suspended = self.TasksSuspendedForSignal[eventName][1];

	self.Scheduler:scheduleTask(suspended,{...});
	table.remove(self.TasksSuspendedForSignal[eventName], 1);

	return true;
end

function Kernel.signalAll(self, eventName, ...)
	if not self.TasksSuspendedForSignal[eventName] then
		return false, "event not registered"
	end

	local nTasks = #self.TasksSuspendedForSignal[eventName]
	if nTasks < 1 then
		return false, "no tasks waiting for event"
	end

	for i=1,nTasks do
		self.Scheduler:scheduleTask(self.TasksSuspendedForSignal[eventName][1],{...});
		table.remove(self.TasksSuspendedForSignal[eventName], 1);
	end

	return true;
end

function Kernel.waitForSignal(self, eventName)
	local currentFiber = self.Scheduler:getCurrentTask();

	if currentFiber == nil then
		return false, "not currently in a running task"
	end

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



function Kernel.run(self, func, ...)

	if func ~= nil then
		self:spawn(func, ...)
	end

	while (self.ContinueRunning) do
		self.Scheduler:step();		
	end
end

function Kernel.halt(self)
	self.ContinueRunning = false;
end

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


return Kernel;
