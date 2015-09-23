schedlua is yet another set of routines concerned with the scheduling
of work to be done in a cooperative multi-tasking system, such as Lua.

Design criteria
- Complexity by composition rather than mololithic structure
- Simplicity through leveraged layering

scheduler
=========
The first set of methods are related to the scheduler.  The sceduler
maintains a 'readyToRun' list of tasks.  Is supports a "scheduleTask()"
function, and not much else.  The scheduler itself does not get involved
in the actual creation of tasks.  It is assumed that they are created
from a different API, and simply handed to the scheduler when scheduling
operations need to occur with.  The basis scheduler is a simple FIFO scheduler, 
which gives no weight to one task over another.

kernel.lua
==========
Although it is possible to program against the scheduler/task combo, you're
actually better off not doing it this way because it is so rough.  Instead, an application should use the kernel module 
local Kernel = require("kernel")


functor.lua
===========

	A functor is a function that can stand in for another function.
	It is somewhat of an object because it retains a certain amount 
	of state.  In this case, it retains the target object, if there is 
	any.

	This is fairly useful when you need to call a function on an object
	at a later time.

	Normally, if the object is constructed thus:

	function obj.func1(self, params)
	end

	You would call the function thus:
	someobj:func1(params)

	which is really
	someobj.func1(someobj, params)

	The object instance is passed into the function as the 'self' parameter
	before the other parameters.

	This is easy enough, but when you're storing the function in a 
	table, for later call, you have a problem because you need to store
	the object instance as well, somewhere.

	This is where the Functor comes in.  It will store both the target
	(if there is one) and the function itself for later execution.

	You can use it like this:

	funcs = {
		routine1 = Functor(obj.func1, someobj);
		routine2 = Functor(obj.func1, someobj2);
		routine3 = Functor(obj.func2, someobj);
	}
	
	Then use it as:
	  funcs.routine1(params);
	  funcs.routine3(params);



References:
* Relevant Blog Entries
** https://williamaadams.wordpress.com/?s=schedlua