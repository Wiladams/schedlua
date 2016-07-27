-- test_timeticker.lua
package.path = package.path..";../?.lua"

local stopwatch = require("schedlua.stopwatch")
local sw = stopwatch();

print("Current Tick: ", sw:seconds())


for i = 1,500 do
	print("i: ", i)
end

print("Ellapsed: ", sw:seconds())
