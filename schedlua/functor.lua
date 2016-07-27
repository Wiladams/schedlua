-- functor.lua
--[[
	A function is a way to attach a function to a target without having
	to construct a table explicitly.

	Example:

	local function printNameField(tbl)
		print(tbl.Name);
	end

	local func = Functor(printNameField, someTable)

	func()

	This construct is useful when you have an instance of a table, which has 
	associated functions, and you want to pass a particular function call within 
	that instance to another function that expects a single value.
	
--]]
local function Functor(func, target)
	return function(...)
		if target then
			return func(target,...)
		end

		return func(...)
	end
end

return Functor