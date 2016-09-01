schedlua is a set of routines that make it relatively easy to create cooperative
multi-tasking applications in LuaJIT.

Design criteria
- Simplicity through minimal coding
- Complexity by composition rather than complex structures
- Compactness through reuse
- minimal number of concepts
- implied operations where possible

The lua programming language is great for multi-tasking because it already contains
the notion of co-routines.  This mechanism provides the means to readily 
compartmentalize operations into easily coded sections.  The challenge of this
method of multi-tasking is that it is cooperative, and you end up with a 
management challenge as the number of independently operating tasks increases.

schedlua provides a couple of key features which make multi-task programming
with lua a lot more manageable.  The first is easy scheduling of tasks.  In a 
cooperative multi-tasking environment, scheduling is nothing more than deciding
which task should run next after the currently running task decides to yield.
schedlua provides a relatively simple scheduling mechanism which deals with this
selection process.

The second feature schedlua provides is a series of well named functions which 
further enable typical multi-tasking tasks.  At the core there are routines that
handle signaling (events).  A task can emit events, as well as wait on events.
Built atop the signaling is a relatively new but useful paradign named predicate
flow control.  This is basically the async equivalent of if/then blocks.  There
are alarms, which provide mechanism for sleeping and delaying executing, and 
last, there is async io operations, particularly as they relate to network
programming.



Here is a typical application:

```lua
local Kernel = require("schedlua.kernel")


local function task1()
	print("first task, first line")
	yield();
	print("first task, second line")
	halt();
end

local function task2()
	print("second task, only line")
end

local function main()
	local t1 = spawn(task1)
	local t2 = spawn(task2)
end

run(main)
```

All applications must begin by including the schedlua.kernel module.
All applications begin execution by explicitly calling the 'run()' function.
The run() function takes an optional function to be executed, so it is 
convenient the create a single function, which in turn has all the code
that you want to execute.

Within this example, there are two calls to the spawn() function.  Each
call to this function will create a separate cooperative task, which will 
in turn be added to the scheduler for execution.  A call to 'spawn' does
not cause the task to execute immediately, but merely to be scheduled for execution.

The runtime will constantly step through the list of tasks ready to be run, 
executing them in turn until each of them reaches a point where they will
yield, and allow for another task to run.

Example Using Time and Predicates
=================================

```lua
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
```

In this example, the timer function 'periodic' is being used, as well as the
predicate function 'when'.  The periodic function is simply executing the 
'printTime' function once every second (1000 milliseconds).  By calling
'periodic', a cooperative task is scheduled, and the program continues on
to the next statement, which is the 'when' call.  The 'when()' function takes
two parameters.  The first is a function which always returns a non-false
value, or false.  When the function returns a non-false value, it will 
then execute the second parameter, which should be a function.  In this case
the 'revertToForm()' function.

So, overall, the example will print the current running time, once a second, and
after 12 seconds, it will print a message, and halt() the program.


References
==========
* Blog Entries
  * https://williamaadams.wordpress.com/?s=schedlua
