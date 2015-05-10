--test_scheduler.lua
package.path = package.path..";../?.lua"

local Kernel = require("kernel"){exportglobal = true}


local function numbers(ending)
	local idx = 0;
	local function closure()
		idx = idx + 1;
		if idx > ending then
			return nil;
		end
		return idx;
	end
	
	return closure;
end

local function task1()
	print("first task, first line")
	yield();
	print("first task, second line")
end

local function task2()
	print("second task, only line")
end

local function counter(name, nCount)
	for num in numbers(nCount) do
		print(name, num);
		yield();
	end
	halt();
end

local function main()
	local t0 = spawn(counter, "counter1", 5)
	local t1 = spawn(task1)
	local t2 = spawn(task2)
	local t3 = spawn(counter, "counter2", 7)
end

run(main)


print("After kernel run...")
