schedlua is a set of routines that make it relatively easy to create cooperative
multi-tasking applications in LuaJIT.

Design criteria
- Simplicity through minimal coding
- Complexity by composition rather than complex structures
- Compactness through reuse
- minimal number of new concepts
- implied operations where possible

The fundamental notion within schedlua is that a scheduler is used to organize which 
of many co-routines are run at any given moment.  co-routines are encapsulated
in a 'task', which can have associated run state as well as other properties.

There are a number of constructs that are enacted through the usage of well named
functions.  These functions are named and organized in such a way as to make
operations feel natural, convenient, and memorable.


Here is a typical application:

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


All applications must begin by including the schedlua.kernel module.
All applications begin execution by explicitly calling the 'run()' function.
The run() function takes an optional funtion to be executed, so it is 
convenient the create a single function, which in turn has all the code
that you want to execute.

Within this application, there are two calls to the spawn() funtion.  Each
call to this function will create a separate cooperative task, which will 
in turn be added to the scheduler for execution.  A call to 'spawn' does
not cause the task to execute immediately, but merely to be scheduled for execution.

The runtime will constantly step through the list of tasks ready to be run, 
executing them in turn until each of them reaches a point where they will
yield, and allow for another task to run.



References:
* Relevant Blog Entries
** https://williamaadams.wordpress.com/?s=schedlua