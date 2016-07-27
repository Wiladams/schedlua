local ffi = require("ffi")

local timeticker = nil;

if ffi.os == "Windows" then
	timeticker = require("schedlua.windows.timeticker")
else
	timeticker = require("schedlua.linux.timeticker")
end


local StopWatch = {}
setmetatable(StopWatch, {
	__call = function(self, ...)
		return self:create(...);
	end;

})

local StopWatch_mt = {
	__index = StopWatch;
}

function StopWatch.init(self, ...)

	local obj = {
		starttime = 0; 
	}
	setmetatable(obj, StopWatch_mt);
	obj:reset();

	return obj;
end


function StopWatch.create(self, ...)
	return self:init();
end

function StopWatch.seconds(self)
	local currentTime = timeticker.seconds();
	return currentTime - self.starttime;
end

function StopWatch.reset(self)
	self.starttime = timeticker.seconds();
end


return StopWatch
