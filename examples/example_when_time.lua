--test_stopwatch.lua

--[[
	An example of how to use time, predicates
	and multiple tasks.
--]]

local Kernel = require("schedlua.kernel")
local StopWatch = require("schedlua.stopwatch")

local sw = StopWatch();


-- A simple conditional which will return true
-- once we pass 12 seconds according to the clock
local function timeExpires()
	return sw:seconds() > 12
end

-- The response to be executed once we reach
-- a time of 12 seconds
local function revertToForm()
	print("Time: ", sw:seconds())
	print("The carriage has reverted to a pumpkin")
	halt();
end


-- The response which will be executed whenever
-- we pass another second
local function printTime()
	print("Time: ", sw:seconds())
end


-- Stitching it all together
local function main()
	periodic(1000, printTime)
	when(timeExpires, revertToForm)
end

run(main)
