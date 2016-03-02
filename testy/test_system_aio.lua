--test_stopwatch.lua
package.path = package.path..";../?.lua"

local ffi = require("ffi")
local bit = require("bit")

local system = require("schedlua.linux")()

local u64 = ffi.typeof("uint64_t");
local i64 = ffi.typeof("int64_t");
local voidp = ffi.typeof("uintptr_t");

local function void(x)
  return ffi.cast(voidp, x)
end

local function test1()
	local ctx = ffi.new("aio_context_t[1]")

	local ret = C.io_setup(128, ctx);
	if (ret < 0) then
		error(string.format("io_setup error: %d", ffi.errno()));
	end

	print("aio_context handle: ", bit.tohex(ctx[0]))

	ret = C.io_destroy(ctx[0]);
	if (ret < 0) then
		error(string.format("io_destroy, error: %d", ffi.errno()))
	end

	return true;
end

local function test2()
	local fd = ffi.C.open("/tmp/testfile", bit.bor(O_RDWR,O_CREAT), 0);
	if (fd < 0) then
		error(string.format("open error: %d", ffi.errno()));
		return false;
	end

	local ctx = ffi.new("aio_context_t[1]");
	local ret = C.io_setup(128, ctx);
	if ret < 0 then
		error(string.format("io_setup error: %d", ffi.errno()));
	end

	-- setup io control block
	local cbs = ffi.new("struct iocb *[1]")
	local cb = ffi.new("struct iocb");
	cb.aio_fildes = fd;
	cb.aio_lio_opcode = ffi.C.IOCB_CMD_PWRITE;

	-- command specific options
	local data = ffi.new("char[4096]");
	cb.aio_buf = u64(void(data));
	cb.aio_offset = 0;
	cb.aio_nbytes = 4096;

	cbs[0] = cb;

	ret = C.io_submit(ctx[0], 1, i64(void(cbs)));
	if ret ~= 1 then
		if ret < 0 then
			error(string.format("io_submit, error: %d", ffi.errno()))
		else
			print(string.format("only submitted %d cbs", ret));
		end

		return false;
	end

	-- get the reply
	local events = ffi.new("struct io_event[1]");
	ret = C.io_getevents(ctx[0], 1, 1, events, nil);
	print("io_getevents: ", ret)

	ret = io_destroy(ctx[0]);
	if ret < 0 then
		error(string.format("io_destroy error: %d", ret))
		return false;
	end

	return true;
end

--test1();
test2();
