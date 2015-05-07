-- functor.lua

local function Functor(func, target)
	return function(...)
		if target then
			return func(target,...)
		end

		return func(...)
	end
end

return Functor