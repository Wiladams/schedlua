--test_stopwatch.lua
package.path = package.path..";../?.lua"

local system = require("linux")



local function test_system_sleep()
	local t1 = system.timespec();
	t1:gettime();
	local starttime = t1:seconds();

	print("Start: ", starttime)

	local remaining = system.sleep(2.5);

	t1:gettime();
	local currenttime = t1:seconds();
	print("End: ", currenttime)

	local duration = currenttime - starttime;

	print("Duration (2.5): ", duration, remaining);
end


test_system_sleep();
