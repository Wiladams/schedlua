--alarm.lua
-- The alarm object is a singleton, so just
-- return the instance if we've already been through
-- this code.
if Alarm_Included then
	return Alarm;
end

local Alarm_Included = true;


local Functor = require("schedlua.functor")
local tabutils = require("schedlua.tabutils")
local Clock = require("schedlua.clock")


local Alarm = {
	ContinueRunning = true;
	SignalsWaitingForTime = {};
	Clock = Clock();
}

setmetatable(Alarm, {
	__call = function(self, kernel, globalize)
		self.Kernel = kernel;
		if globalize then
			self:globalize();
		end

		self:run();

		return self;
	end;
})

local function compareDueTime(task1, task2)
	if task1.DueTime < task2.DueTime then
		return true
	end
	
	return false;
end


function Alarm.waitUntilTime(self, atime)
	-- create a signal
	local taskID = self.Kernel:getCurrentTaskID();
	local signalName = "sleep-"..tostring(taskID);
	local fiber = {DueTime = atime, SignalName = signalName};

	-- put time/signal into list so watchdog will pick it up
	tabutils.binsert(self.SignalsWaitingForTime, fiber, compareDueTime)

	-- put the current task to wait on signal
	self.Kernel:waitForSignal(signalName);
end

function Alarm.sleep(self, millis)
	-- figure out the time in the future
	local currentTime = self.Clock:getCurrentTime();
	local futureTime = currentTime + (millis / 1000);
	return self:waitUntilTime(futureTime);
end

function Alarm.delay(self, func, millis)
	millis = millis or 1000

	local function closure()
		self:sleep(millis)
		func();
	end

	return self.Kernel:spawn(closure)
end

function Alarm.periodic(self, func, millis)
	millis = millis or 1000

	local function closure()
		while true do
			self:sleep(millis)
			func();
		end
	end

	return self.Kernel:spawn(closure)
end

-- The routine task which checks the list of waiting tasks to see
-- if any of them need to be signaled to wakeup
function Alarm.watchdog(self)
	while (self.ContinueRunning) do
		local currentTime = self.Clock:getCurrentTime();
		-- traverse through the fibers that are waiting
		-- on time
		local nAwaiting = #self.SignalsWaitingForTime;
		--print("Timer Events Waiting: ", nAwaiting)
		for i=1,nAwaiting do

			local fiber = self.SignalsWaitingForTime[1];
			if fiber.DueTime <= currentTime then
				self.Kernel:signalOne(fiber.SignalName);

				table.remove(self.SignalsWaitingForTime, 1);

			else
				break;
			end
		end		
		self.Kernel:yield();
	end
end


function Alarm.run(self)
	self.Kernel:spawn(Functor(Alarm.watchdog, Alarm))
end


function Alarm.globalize(self)
	_G["delay"] = Functor(Alarm.delay, Alarm);
	_G["periodic"] = Functor(Alarm.periodic, Alarm);
	_G["sleep"] = Functor(Alarm.sleep, Alarm);

	return self;
end

return Alarm
