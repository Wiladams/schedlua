scheduler
=========

The scheduler is the primary mechanism used to organize and coordinate
which task is to be run at any given time.  The application is essentially
a single thread of execution, but tasks will relinquish control at 
convenient times in order to allow other tasks to perform until they
relinquish control.

The scheduler maintains a ReadyToRun list, which is essentially a queue
of the tasks which have been scheduled to run, through calling the
'scheduleTask()' function.

Through repeated calls to the 'step()' function, each task is retrieved
from the ReadyToRun list, and resumed.  Once the task performs a 'yield()'
it goes back on the ReadyToRun list, and the next task from the list 
is executed.

The scheduler as currently implemented uses a simple queue as the 
ReadyToRun list.  This provides for an easy to understand 
first in first out (FIFO) management mechanism.  That is, all tasks
are considered equal, and they are executed in the order in which 
they were added to the schedule.

There is a convenience method for putting a task at the front of the list.
Calling scheduleTask(self, task, params, priority), with a priority of '0'
will cause the tasks to be placed at the beginning of the list, to be 
executed next.

This rudimentary prioritization should be used sparinging.  If a high 
priority task is placed at the front of the list repeatedly, it could
cause starvation of the other tasks, and they will never get a chance
to be run.

