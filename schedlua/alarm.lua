--alarm.lua
--[[
	Implied global kernel
--]]

if Alarm then
	return Alarm
end


local tabutils = require("schedlua.tabutils")
local stopwatch = require("schedlua.stopwatch")

local	ContinueRunning = true;
local	SignalsWaitingForTime = {};
local	SWatch = stopwatch();

local function runningTime()
	return SWatch:seconds();
end

local function compareDueTime(task1, task2)
	if task1.DueTime < task2.DueTime then
		return true
	end
	
	return false;
end


function waitUntilTime(atime)
	-- create a signal
	local taskID = getCurrentTaskID();
	local signalName = "sleep-"..tostring(taskID);
	local fiber = {DueTime = atime, SignalName = signalName};

	-- put time/signal into list so watchdog will pick it up
	tabutils.binsert(SignalsWaitingForTime, fiber, compareDueTime)

	-- put the current task to wait on signal
	waitForSignal(signalName);
end

-- suspend the current task for the 
-- specified number of milliseconds
local function sleep(millis)
	-- figure out the time in the future
	local currentTime = SWatch:seconds();
	local futureTime = currentTime + (millis / 1000);
	
	return waitUntilTime(futureTime);
end

local function delay(millis, func)
	millis = millis or 1000

	local function closure()
		sleep(millis)
		func();
	end

	return spawn(closure)
end

local function periodic(millis, func)
	millis = millis or 1000

	local function closure()
		while true do
			sleep(millis)
			func();
		end
	end

	return spawn(closure)
end

-- The routine task which checks the list of waiting tasks to see
-- if any of them need to be signaled to wakeup
local function taskReadyToRun()
	local currentTime = SWatch:seconds();
	
	-- traverse through the fibers that are waiting
	-- on time
	local nAwaiting = #SignalsWaitingForTime;

	for i=1,nAwaiting do
		local task = SignalsWaitingForTime[1]; 
		if not task then
			return false;
		end

		if task.DueTime <= currentTime then
			return task
		else
			return false
		end
	end

	return false;
end

local function runTask(task)
	signalOne(task.SignalName);
	table.remove(SignalsWaitingForTime, 1);
end


local function globalize(tbl)
	tbl = tbl or _G

	rawset(tbl,"delay",delay);
	rawset(tbl,"periodic",periodic);
	rawset(tbl,"runningTime",runningTime);
	rawset(tbl,"sleep",sleep);

	return tbl;
end

globalize();


-- This is a global variable because These routines
-- MUST be a singleton within a lua state
Alarm = whenever(taskReadyToRun, runTask)

return Alarm
