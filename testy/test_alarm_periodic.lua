--test_stopwatch.lua
package.path = package.path..";../?.lua"

local Kernel = require("schedlua.kernel")();
local StopWatch = require("schedlua.stopwatch")

local sw = StopWatch();


local function haltAfterTime(msecs)
	local function closure()
		print("READY TO HALT: ", msecs, sw:seconds());
		halt();
	end

	delay(msecs, closure);	-- halt after specified seconds
end

local function everyPeriod()
	print("PERIODIC: ", sw:seconds());
end

local function main()
	periodic(250, everyPeriod)
	haltAfterTime(5000);
end

run(main)
