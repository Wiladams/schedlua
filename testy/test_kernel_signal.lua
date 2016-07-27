--test_kernel_signal.lua
--[[
	A rudimentary test of the kernel signaling routines.
	This test runs a counter which generates a stream of well named
	events.  A couple of routines will respond to the appropriate events
	using signalOne().

	The halt() routine will respond to the 'counter-finished' event
	which is signaled with signalAll()
--]]
package.path = package.path..";../?.lua"

local Kernel = require("schedlua.kernel")



--[[
	counter

	This routine serves the purpose of generating signals
	based on the iteration of a series of numbers.

	The name of the signal is derived from the concatenation of 
	the name parameter passed into the function, and the current
	numerical value of the iteration.

	During each iteration, a single task is signaled (with signalOne)
	and the counter yields, allowing that task to actually execute.

	At the end of the enumeration, all tasks that are waiting on the 'finished'
	event are signaled (with signalAll()).
--]]
local function counter(name, nCount)
	for num=1, nCount do
		local eventName = name..tostring(num);
		print(eventName)

		signalOne(eventName);
		yield();
	end

	signalAll(name..'-finished')
end

-- A task which will wait for the count of 15
-- and print a message
function wait15() 
	waitForSignal("counter15") 
	print("reached 15!!") 
end

-- A task which will wait for the count of 20
-- and print a message.
function wait20() 
	waitForSignal("counter20") 
	print("reached 20!!") 
end


local function main()
	-- Spawn the task which will generate a steady stream of signals
	local t1 = spawn(counter, "counter", 25)

	-- spawn a couple of tasks which will respond to reaching
	-- specific counting events
	local t2 = spawn(wait20)
	local t3 = spawn(wait15)

	-- setup to call halt when counting is finished
	onSignal("counter-finished", halt)
end

run(main)
