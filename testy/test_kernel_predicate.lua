--test_scheduler.lua
package.path = package.path..";../?.lua"

local Functor = require("schedlua.functor")
local Kernel = require("schedlua.kernel")()
local Predicate = require("schedlua.predicate")(Kernel, true)

local idx = 0;
local maxidx = 100;

local function numbers(ending)
	local function closure()
		idx = idx + 1;
		if idx > ending then
			return nil;
		end
		return idx;
	end
	
	return closure;
end



local function counter(name, nCount)
	for num in numbers(nCount) do
		print(num)
		local eventName = name..tostring(num);
		--print(eventName)
		signalOne(eventName);

		yield();
	end

	signalAll(name..'-finished')
end


local function predCount(num)
	waitForPredicate(function() return idx > num end)
	print(string.format("PASSED: %d!!", num))
end



local function every5()
	while idx <= maxidx do
		waitForPredicate(function() return (idx % 5) == 0 end)
		print("!! matched 5 !!")
		yield();
	end
end

local function test_whenever()
	local t1 = whenever(
		function() 
			if idx >maxidx then return nil end; 
			return (idx % 2) == 0 end,
		function() print("== EVERY 2 ==") end)
end

local function main()
	local t1 = spawn(counter, "counter", maxidx)

	local t6 = spawn(test_whenever);

	local t2 = spawn(predCount, 12)
	local t3 = spawn(every5)
	local t4 = spawn(predCount, 50)
	local t5 = when(
		function() return idx == 75 end, 
		function() print("WHEN IDX == 75!!") end)
	local t6 = when(function() return idx >= maxidx end,
		function() halt(); end);


end

run(main)


