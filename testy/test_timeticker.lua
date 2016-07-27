-- test_timeticker.lua
package.path = package.path..";../?.lua"

local ticker = require("schedlua.windows.timeticker")

print("Current Tick: ", ticker.seconds())

local startAt = ticker.seconds();

for i = 1,1000 do
	print("i: ", i)
end
local endAt = ticker.seconds();

print("Ellapsed: ", endAt - startAt)
