--test_stopwatch.lua
package.path = package.path..";../?.lua"

local Kernel = require("kernel"){exportglobal = true};
local Alarm = require("alarm")(Kernel)
local Clock, timespec = require("clock")



local function test_alarm_sleep()
	local s1 = Clock();
	local starttime = s1:secondsElapsed();
	print("Start: ", starttime)

	Alarm:sleep(7525);

	local currenttime = s1:secondsElapsed();
	print("End: ", currenttime)

	local duration = currenttime - starttime;

	print("Duration: ", duration, remaining);

	halt();
end

run(test_alarm_sleep)
