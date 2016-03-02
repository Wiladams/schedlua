--predicate.lua
local Functor = require("schedlua.functor")

local Predicate = {}
setmetatable(Predicate, {
	__call = function(self, kernel, globalize)
		self.Kernel = kernel;
		if globalize then
			self:globalize();
		end
		return self;
	end;
})


function Predicate.signalOnPredicate(self, pred, signalName)
	local function closure()
		local res = nil;
		repeat
			res = pred();
			if res == true then 
				return self.Kernel:signalAll(signalName) 
			end;

			self.Kernel:yield();
		until res == nil
	end

	return self.Kernel:spawn(closure)
end

function Predicate.waitForPredicate(self, pred)
	local signalName = "predicate-"..tostring(self.Kernel:getCurrentTaskID());
	self:signalOnPredicate(pred, signalName);
	return self.Kernel:waitForSignal(signalName);
end

function Predicate.when(self, pred, func)
	local function closure(lpred, lfunc)
		self:waitForPredicate(lpred)
		lfunc()
	end

	return self.Kernel:spawn(closure, pred, func)
end

function Predicate.whenever(self, pred, func)

	local function closure(lpred, lfunc)
		local signalName = "whenever-"..tostring(self.Kernel:getCurrentTaskID());
		local res = true;
		repeat
			self:signalOnPredicate(lpred, signalName);
			res = self.Kernel:waitForSignal(signalName);
			lfunc()
		until false
	end

	return self.Kernel:spawn(closure, pred, func)
end

function Predicate.globalize(self)
	_G["signalOnPredicate"] = Functor(Predicate.signalOnPredicate, Predicate);
	_G["waitForPredicate"] = Functor(Predicate.waitForPredicate, Predicate);
	_G["when"] = Functor(Predicate.when, Predicate);
	_G["whenever"] = Functor(Predicate.whenever, Predicate);

end

return Predicate
