--test_stopwatch.lua
package.path = package.path..";../?.lua"

local Kernel = require("kernel"){exportglobal = true};
local Alarm = require("alarm")(Kernel)
local Clock, timespec = require("clock")



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
