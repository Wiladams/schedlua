--test_stopwatch.lua
package.path = package.path..";../?.lua"

local Clock = require("clock")


local function donothing()
	-- idle for a little bit
	for i=1, 100000 do
		print("nothing")
	end
end



local function test_clock()
	local s1 = Clock();
	local starttime = s1:secondsElapsed();

	print("Start: ", starttime)

	donothing();

	local currenttime = s1:secondsElapsed();
	print("End: ", currenttime)

	local duration = currenttime - starttime;

	print("Duration: ", duration);
end


test_clock();
