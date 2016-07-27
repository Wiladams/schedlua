--test_scheduler.lua
package.path = package.path..";../?.lua"

--[[
	In this we are testing the simple predicate waiting mechanism
	The spawn method is used to create a couple of tasks which will
	in turn use 'waitForTruth' to suspend themselves until
	the predicate returns a 'true' value.  Then they print their message.
--]]

local Kernel = require("schedlua.kernel")


local idx = 0;
local maxidx = 25;


local function counter(name, nCount)
	for num=1, nCount do
		idx = num
		local eventName = name..tostring(idx);
		print(eventName, idx)
		signalOne(eventName);

		yield();
	end

	signalAll(name..'-finished')
end


local function predCount(num)
	waitForTruth(function() return idx == num end)
	print(string.format("PASSED: %d!!", num))
end


local function main()
	local t1 = spawn(counter, "counter", maxidx)

	local t2 = spawn(predCount, 12)
	local t4 = spawn(predCount, 20)


	-- setup to call halt when counting is finished
	onSignal("counter-finished", halt)
end

run(main)
