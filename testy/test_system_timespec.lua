--test_stopwatch.lua
package.path = package.path..";../?.lua"

local system = require("linux")();


local function main()
	local resolution = timespec();
	local res = resolution:getresolution();

	print("clock_getres: ", res, resolution.tv_sec, resolution.tv_nsec);

	local time1 = timespec();
	res = time1:gettime();
	print("clock_gettime: ", time1.tv_sec, time1.tv_nsec);


	local time2 = timespec();
	res = time2:gettime();
	print("clock_gettime: ", res, time2.tv_sec, time2.tv_nsec);

	local elapsed = time2:seconds() - time1:seconds();
	print("elapsed: ", elapsed);
end

main();
