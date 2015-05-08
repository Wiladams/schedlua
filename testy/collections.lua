--[[
	Collections.lua

	This file contains a few collection classes that are
	useful for many things.  The most basic object is the
	simple list.

	From the list is implemented a queue
--]]
local setmetatable = setmetatable;


--[[
	A bag behaves similar to a dictionary.
	You can add values to it using simple array indexing
	You can also retrieve values based on array indexing
	The one addition is the '#' length operator works
--]]
local Bag = {}
setmetatable(Bag, {
	__call = function(self, ...)
		return self:_new(...);
	end,
})

local Bag_mt = {
	__index = function(self, key)
		--print("__index: ", key)
		return self.tbl[key]
	end,

	__newindex = function(self, key, value)		
		--print("__newindex: ", key, value)
		if value == nil then
			self.__Count = self.__Count - 1;
		else
			self.__Count = self.__Count + 1;
		end

		--rawset(self, key, value)
		self.tbl[key] = value;
	end,

	__len = function(self)
--		print("__len: ", self.__Count)
		return self.__Count;
	end,

	__pairs = function(self)
		return pairs(self.tbl)
	end,
}

function Bag._new(self, obj)
	local obj = {
		tbl = {},
		__Count = 0,
	}

	setmetatable(obj, Bag_mt);

	return obj;
end


-- The basic list type
-- This will be used to implement queues and other things
local List = {}
local List_mt = {
	__index = List;
}

function List.new(params)
	local obj = params or {first=0, last=-1}

	setmetatable(obj, List_mt)

	return obj
end


function List:PushLeft (value)
	local first = self.first - 1
	self.first = first
	self[first] = value
end

function List:PushRight(value)
	local last = self.last + 1
	self.last = last
	self[last] = value
end

function List:PopLeft()
	local first = self.first

	if first > self.last then
		return nil, "list is empty"
	end
	local value = self[first]
	self[first] = nil        -- to allow garbage collection
	self.first = first + 1

	return value
end

function List:PopRight()
	local last = self.last
	if self.first > last then
		return nil, "list is empty"
	end
	local value = self[last]
	self[last] = nil         -- to allow garbage collection
	self.last = last - 1

	return value
end

--[[
	Stack
--]]
local Stack = {}
setmetatable(Stack,{
	__call = function(self, ...)
		return self:new(...);
	end,
});

local Stack_mt = {
	__len = function(self)
		return self.Impl.last - self.Impl.first+1
	end,

	__index = Stack;
}

Stack.new = function(self, ...)
	local obj = {
		Impl = List.new();
	}

	setmetatable(obj, Stack_mt);

	return obj;
end

Stack.len = function(self)
	return self.Impl.last - self.Impl.first+1
end

Stack.push = function(self, item)
	return self.Impl:PushRight(item);
end

Stack.pop = function(self)
	return self.Impl:PopRight();
end




return {
	Bag = Bag;
	List = List;
	Stack = Stack;
}

