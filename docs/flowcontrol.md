Flow Control
============

The 'if-then-else' construct is the most usual mechanism for flow control in
a typical serial application.  Schedlua introduces a few more constructs which 
make it easier to reason about programming in a multi-tasking environment.

At the core of any flow control construct is a boolean test.
```lua
	if conditionisTrue then
  		performsomeaction()
	end
```

In a single tasking environment, this is easy to understand, as when the 
condition is true, the action is performed, otherwise it is not.  

The first flow control construct schedlua introduces is that of the 
suspending a task until a particular condition is met.  So, whereas the
simple 'if' statement is a one time test, 'waitForTruth' will suspend
the task indefinitely, until the condition is met.

```lua
	local counter = 0;
	local function counterIsFive()
		counter = counter + 1;
		if counter >= 5 then return true end

		return false
	end

	-- executing some code serially
	waitForTruth(counterIsFive)

	-- continue to execute
	print(counter)
```

In this case, the task that is currently executing will be suspended when it makes
the call to 'waitForTruth'.  It will remain in this suspended state as long as the 
'somecondition' function returns 'false'.  Once it returns true, the task will
continue from the point at which it was suspended.

Suspending the current task in place is useful, and most similar to a simple while loop.
What if you want to disassociate the conditional check from the current task, and
essentially just have some bit of code execute cooperatively when the condition
proves to be true?

	`when(conditionisTrue, action)`

The implementation of this construct is the following:
```lua
local function when(pred, func)
	local function closure(lpred, lfunc)
		waitForPredicate(lpred)
		lfunc()
	end

	return spawn(closure, pred, func)
end
```

This is a matter of convenience.  A task is spawned which will be suspended until 
the condition is true.  Once the condition is true, the specified action will
be performed.

This is similar to the signaling construct, but the 'signal' is given by a function
returning a true value, rather than some other mechanism.  The truth is, the signaling
mechanism with schedlua is actually at the core of the implementation of the
waitForPredicate() function.


Another supported construct is when you want to perform the action repeatedly,
rather than doing a one shot, as is the case with the 'when' construct.  The 'whenever'
construct will serve this purpose.

`whenever(condition, action)`

In this case, once the condition returns 'true', the action is performed, and the
condition continues to be check, and the action continues to be performed for each
'true' value.  This will go on forever.

In other environments, signaling and callbacks are supported.  At their core, these
constructs are very similar.  The ways in which they differ are perhaps subtle, but
very useful.  First is the naming itself.  In English, it's fairly easy to understand
the words 'when', and 'whenever', and even 'waitForTruth'.  That makes forming a program
with these constructs fairly easy to remember.  The more subtle aspect though is the 
usage of implied spawned tasks.  This essentially decouples that condition and execution
from the calling site.  You do not end up with long chains of callback branches, where 
you need to keep track of failure states.  You essentially just write simple code
which is strung together with fairly simple statements.

Here is a program which spawns a task which is a counter, and then
uses the 'when' construct to halt the program once we have determined
counting has finished.

```lua
local Kernel = require("schedlua.kernel")

local idx = 0;
local maxidx = 20;


local function counter(name, nCount)
	for num=1, nCount do
		idx = num
		yield();
	end
end

local function countingFinished()
	return idx >= maxidx;
end

local function main()
	local t1 = spawn(counter, "counter", maxidx)

	when(countingFinished, halt)
end

run(main)
```


Here is another program, which uses the 'whenever' construct to repeatedly perform
actions based on some conditions.  It also uses the signaling mechanism to 
halt the program, just to show how these two can be mixed.

```lua
local Kernel = require("schedlua.kernel")

local idx = 0;
local maxidx = 20;


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

local function every5()
	local lastidx = 0;
	
	while idx <= maxidx do
		waitForPredicate(function() return (idx % 5) == 0 end)
		if idx > lastidx then
			print("!! matched 5 !!")
			lastidx = idx;
			--yield();
		end
	end
end

local function test_whenever(modulus)
	local lastidx = 0;

	local function modulustest()
		--print("modulustest: ", idx, lastidx, maxidx)
		if idx > maxidx then
			return false;
		end

		if idx > lastidx then
			lastidx = idx;
			return (idx % modulus) == 0
		end
	end

	local t1 = whenever(modulustest, function() print("== EVERY: ", modulus) end)

	return t1;
end

local function main()
	local t1 = spawn(counter, "counter", maxidx)

	test_whenever(2);
	test_whenever(5);


	-- setup to call halt when counting is finished
	onSignal("counter-finished", halt)
end

run(main)
```

So, that is how you can begin to construct multi-tasking programs using the
'when' and 'whenever' constructs.  They are essentially a combination of 
a signal and a spawn, and in the case of whenever, a repeating loop.
