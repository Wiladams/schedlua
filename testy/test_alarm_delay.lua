--test_stopwatch.lua
package.path = "../?.lua;"..package.path

local Kernel = require("schedlua.kernel")
local StopWatch = require("schedlua.stopwatch")

local sw = StopWatch();

local function twoSeconds()
	print("TWO SECONDS: ", sw:seconds());
	halt();
end

local function main()
	print("delay(2000, twoSeconds)");
	delay(2000, twoSeconds);
end

run(main)
