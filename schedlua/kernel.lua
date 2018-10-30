-- kernel.lua
-- The kernel is the central figure in schedlua.  There is a single
-- instance of the kernel within a single lua state, so the kernel
-- is a global variable.
-- If it has already been created, we simply return that single instance.

--print("== KERNEL INCLUDED ==")

if Kernel ~= nil then
	return Kernel;
end

local Scheduler = require("schedlua.scheduler")
local Task = require("schedlua.task")

Kernel = {
	ContinueRunning = true;
	TaskID = 0;
	Scheduler = Scheduler();
	TasksSuspendedForSignal = {};
}
local Kernel = Kernel;


local function getNewTaskID()
	Kernel.TaskID = Kernel.TaskID + 1;
	return Kernel.TaskID;
end

local function getCurrentTask()
	return Kernel.Scheduler:getCurrentTask();
end

local function getCurrentTaskID()
	return getCurrentTask().TaskID;
end


local function inMainTask()
	return coroutine.running() == nil; 
end

local function coop(priority, func, ...)
	local task = Task(func, ...)
	task.TaskID = getNewTaskID();
	task.Priority = priority;
	return Kernel.Scheduler:scheduleTask(task, {...});
end

local function spawn(func, ...)
	return coop(100, func, ...);
end

local function yield(...)
	return coroutine.yield(...);
end

local function suspend(...)
	Kernel.Scheduler:suspendCurrentTask();
	return yield(...)
end


local function signalTasks(eventName, priority, allofthem, ...)
	local tasklist = Kernel.TasksSuspendedForSignal[eventName];

	if not  tasklist then
		return false, "event not registered", eventName
	end

	local nTasks = #tasklist
	if nTasks < 1 then
		return false, "no tasks waiting for event"
	end

	if allofthem then
		local allparams = {...}
		for i=1,nTasks do
			Kernel.Scheduler:scheduleTask(tasklist[1],allparams, priority);
			table.remove(tasklist, 1);
		end
	else
		Kernel.Scheduler:scheduleTask(tasklist[1],{...}, priority);
		table.remove(tasklist, 1);
	end

	return true;
end

local function signalOne(eventName, ...)
	return signalTasks(eventName, 100, false, ...)
end

local function signalAll(eventName, ...)
	return signalTasks(eventName, 100, true, ...)
end

local function signalAllImmediate(eventName, ...)
	return signalTasks(eventName, 0, true, ...)
end

local function waitForSignal(eventName,...)
	local currentFiber = Kernel.Scheduler:getCurrentTask();

	if currentFiber == nil then
		return false, "not currently in a running task"
	end

	if not Kernel.TasksSuspendedForSignal[eventName] then
		Kernel.TasksSuspendedForSignal[eventName] = {}
	end

	table.insert(Kernel.TasksSuspendedForSignal[eventName], currentFiber);

	return suspend(...)
end

local function onSignal(eventName, func)
	local function closure()
		waitForSignal(eventName)
		func();
	end

	return spawn(closure)
end



local function run(func, ...)

	if func ~= nil then
		spawn(func, ...)
	end

	while (Kernel.ContinueRunning) do
		Kernel.Scheduler:step();		
	end
end

local function halt(self)
	Kernel.ContinueRunning = false;
end

local function globalize(tbl)
	tbl = tbl or _G;

	rawset(tbl, "Kernel", Kernel);

	-- task management
	rawset(tbl, "halt", halt);
	rawset(tbl,"run", run);
	rawset(tbl,"coop", coop);
	rawset(tbl,"spawn", spawn);
	rawset(tbl,"suspend", suspend);
	rawset(tbl,"yield", yield);

	-- signaling
	rawset(tbl,"onSignal", onSignal);
	rawset(tbl,"signalAll", signalAll);
	rawset(tbl,"signalAllImmediate", signalAllImmediate);
	rawset(tbl,"signalOne", signalOne);
	rawset(tbl,"waitForSignal", waitForSignal);

	-- extras
	rawset(tbl,"getCurrentTaskID", getCurrentTaskID);

	return tbl;
end

-- We globalize before including the extras because they will 
-- assume the global state is already set, and spawning and signaling
-- are already available.

local global = globalize();

-- Extra non-core routines
local Predicate = require("schedlua.predicate")
local Alarm = require("schedlua.alarm")

return globalize;

