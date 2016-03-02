--test_stopwatch.lua
package.path = package.path..";../?.lua"

local Kernel = require("schedlua.kernel")()
local Alarm = require("schedlua.alarm")(Kernel)
local Clock, timespec = require("schedlua.clock")

local c1 = Clock();

local function twoSeconds()
	print("TWO SECONDS: ", c1:secondsElapsed());
	Kernel:halt();
end

local function test_alarm_delay()
	print("delay(twoSeconds, 2000");
	Alarm:delay(twoSeconds, 2000);
end

run(test_alarm_delay)
