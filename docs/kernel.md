kernel
======
Schedlua is a multi-tasking environment.  It supports the easy creation of applications
that utilize multiple cooperating tasks, and managing the complex interactions of those
tasks.

Any program that uses schedlua must begin by including the 'schedlua.kernel' module.

local Kernel = require("schedlua.kernel")

There is only a single Kernel module for any given lua state, so even though you can
include the module multiple times, you will only have a single instance.

Once you include this module, it will add several functions to the global namespace.
they are the following.

Runtime management
==================
run
halt

Task management
===============
coop
suspend
yield

Signaling
=========
onSignal
signalTasks
signalOne
signalAll
signalAllImmediate
waitForSignal

Predicates
==========
signalOnPredicate
waitForTruth
when
whenever

Alarms
======
delay
periodic
sleep

IO Events
=========
waitForIOEvent
watchForIOEvents

