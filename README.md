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
actually better off not doing it this way because it is so rough.  Instead, an
application should use the module require("lua").
luajit 