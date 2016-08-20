local ffi = require("ffi")


-- mostly from time.h
ffi.cdef[[
typedef int32_t       clockid_t;
typedef long          time_t;

struct timespec {
  time_t tv_sec;
  long   tv_nsec;
};
]]

local timespec = ffi.typeof("struct timespec")

ffi.cdef[[
int clock_getres(clockid_t clk_id, struct timespec *res);
int clock_gettime(clockid_t clk_id, struct timespec *tp);
int clock_settime(clockid_t clk_id, const struct timespec *tp);
int clock_nanosleep(clockid_t clock_id, int flags, const struct timespec *request, struct timespec *remain);

static const int CLOCK_REALTIME			= 0;
static const int CLOCK_MONOTONIC			= 1;
static const int CLOCK_PROCESS_CPUTIME_ID	= 2;
static const int CLOCK_THREAD_CPUTIME_ID	= 3;
static const int CLOCK_MONOTONIC_RAW		= 4;
static const int CLOCK_REALTIME_COARSE		= 5;
static const int CLOCK_MONOTONIC_COARSE	= 6;
static const int CLOCK_BOOTTIME			= 7;
static const int CLOCK_REALTIME_ALARM		= 8;
static const int CLOCK_BOOTTIME_ALARM		= 9;
static const int CLOCK_SGI_CYCLE			= 10;	// Hardware specific 
static const int CLOCK_TAI					= 11;

]]


local function GetCurrentTickTime()
	local tspec = timespec();
	local res = ffi.C.clock_gettime(ffi.C.CLOCK_REALTIME, tspec)

	if res ~= 0 then
		return false, ffi.errno();
	end

	local secs = tonumber(tspec.tv_sec) + (tonumber(tspec.tv_nsec) / 1000000000);	-- one billion'th of a second

	return secs;
end





return {	
	seconds = GetCurrentTickTime,
}

