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
local function watchdog()
	while (ContinueRunning) do
		local currentTime = SWatch:seconds();
		-- traverse through the fibers that are waiting
		-- on time
		local nAwaiting = #SignalsWaitingForTime;
		--print("Timer Events Waiting: ", nAwaiting)
		for i=1,nAwaiting do

			local fiber = SignalsWaitingForTime[1];
			if fiber.DueTime <= currentTime then
				signalOne(fiber.SignalName);

				table.remove(SignalsWaitingForTime, 1);
			else
				break;
			end
		end		
		yield();
	end
end



local function globalize(tbl)
	tbl = tbl or _G

	tbl["delay"] = delay;
	tbl["periodic"] = periodic;
	tbl["runningTime"] = runningTime;
	tbl["sleep"] = sleep;

	return tbl;
end

globalize();


-- This is a global variable because These routines
-- MUST be a singleton within a lua state
Alarm = spawn(watchdog)

return Alarm
