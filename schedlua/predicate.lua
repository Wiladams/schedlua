--predicate.lua

--[[
	This, implementation of cooperative flow control mechanisms.
	The routines essentially wrap basic signaling with convenient words
	and spawning operations.

	The fundamental building block is the 'predicate', which is nothing more
	than a function which returns a boolean value.

	The typical usage will be to block a task with 'waitForPredicate', which will
	suspend the current task until the specified predicate returns a value of 'true'.
	It will then be resumed from that point.

	waitForPredicate
	signalOnPredicate
	when
	whenever
--]]

local spawn = spawn;
local signalAll = signalAll;
local signalOne = signalOne;
local getCurrentTaskID = getCurrentTaskID;


local function waitForPredicate(pred)
	local signalName = "predicate-"..tostring(getCurrentTaskID());
	signalOnPredicate(pred, signalName);
	return waitForSignal(signalName);
end

local function signalOnPredicate(pred, signalName)
	local function closure(lpred)
		local res = nil;
		repeat
			res = lpred();
			if res then 
				return signalAllImmediate(signalName, res) 
			end;

			yield();
		until res == nil
	end

	return spawn(closure, pred)
end



local function when(pred, func)
	local function closure(lpred, lfunc)
		lfunc(waitForPredicate(lpred))
	end

	return spawn(closure, pred, func)
end

local function whenever(pred, func)
	local function closure(lpred, lfunc)
		local signalName = "whenever-"..tostring(getCurrentTaskID());
		local res = true;
		repeat
			signalOnPredicate(lpred, signalName);
			res = waitForSignal(signalName);
			lfunc(res)
		until false
	end

	return spawn(closure, pred, func)
end

local function globalize(tbl)
	tbl = tbl or _G;

	rawset(tbl,"signalOnPredicate", signalOnPredicate);
	rawset(tbl,"waitForPredicate", waitForPredicate);
	rawset(tbl,"waitForTruth", waitForPredicate);
	rawset(tbl,"when", when);
	rawset(tbl,"whenever", whenever);

	return tbl;
end

return globalize()

