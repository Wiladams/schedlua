--test_stopwatch.lua
package.path = package.path..";../?.lua"

local Kernel = require("schedlua.kernel")();
local Alarm = require("schedlua.alarm")(Kernel)
local Clock, timespec = require("schedlua.clock")



local function test_alarm_sleep()
	local s1 = Clock();
	local starttime = s1:reset();
	print("sleep(7525)");

	Alarm:sleep(7525);

	local duration = s1:secondsElapsed();

	print("Duration: ", duration);

	halt();
end

run(test_alarm_sleep)
