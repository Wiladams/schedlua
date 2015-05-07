local ffi = require("ffi")
local bit = require("bit")



local system = require("linux")

local Clock = {}
setmetatable(Clock, {
	__call = function(self, ...)
		return self:create(...);
	end;

})

local Clock_mt = {
	__index = Clock;
}

function Clock.init(self, ...)

	local obj = {
		tspec = system.timespec();	-- used so we don't create a new one every time
		starttime = 0; 
	}
	setmetatable(obj, Clock_mt);
	obj:reset();

	return obj;
end


function Clock.create(self, ...)
	return self:init();
end

function Clock.getCurrentTime(self)
	local res = self.tspec:gettime();
	local currentTime = self.tspec:seconds();
	return currentTime;
end

function Clock.secondsElapsed(self)
	local res = self.tspec:gettime()
	local currentTime = self.tspec:seconds();
	return currentTime - self.starttime;
end

function Clock.reset(self)
	local res = self.tspec:gettime()
	self.starttime = self.tspec:seconds();
end


return Clock, timespec;
