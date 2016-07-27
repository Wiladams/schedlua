--test_stopwatch.lua
package.path = package.path..";../?.lua"

local Kernel = require("schedlua.kernel")
local StopWatch = require("schedlua.stopwatch")

local sw = StopWatch();



local function main()
	local starttime = sw:reset();
	print("sleep(3525)");

	sleep(3525);

	local duration = sw:seconds();

	print("Duration: ", duration);

	halt();
end

run(main)
