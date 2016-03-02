--epoll_set.lua

local ffi = require("ffi")
local bit = require("bit")
local lshift, rshift, bor, band = bit.lshift, bit.rshift, bit.bor, bit.band;

local exports = {}

--[[
	Things related to epoll
--]]

exports.EPOLLIN 	= 0x0001;
exports.EPOLLPRI 	= 0x0002;
exports.EPOLLOUT 	= 0x0004;
exports.EPOLLRDNORM = 0x0040;			-- SAME AS EPOLLIN
exports.EPOLLRDBAND = 0x0080;
exports.EPOLLWRNORM = 0x0100;			-- SAME AS EPOLLOUT
exports.EPOLLWRBAND = 0x0200;
exports.EPOLLMSG	= 0x0400;			-- NOT USED
exports.EPOLLERR 	= 0x0008;
exports.EPOLLHUP 	= 0x0010;
exports.EPOLLRDHUP 	= 0x2000;
exports.EPOLLWAKEUP = lshift(1,29);
exports.EPOLLONESHOT = lshift(1,30);
exports.EPOLLET 	= lshift(1,31);




-- Valid opcodes ( "op" parameter ) to issue to epoll_ctl().
exports.EPOLL_CTL_ADD =1	-- Add a file descriptor to the interface.
exports.EPOLL_CTL_DEL =2	-- Remove a file descriptor from the interface.
exports.EPOLL_CTL_MOD =3	-- Change file descriptor epoll_event structure.

ffi.cdef[[
/* Flags to be passed to epoll_create1.  */
enum
  {
    EPOLL_CLOEXEC = 02000000
  };
]]

ffi.cdef[[
typedef union epoll_data {
  void *ptr;
  int fd;
  uint32_t u32;
  uint64_t u64;
} epoll_data_t;
]]

--[=[
ffi.cdef[[
struct epoll_event {
  uint32_t events;
  epoll_data_t data;
};
]]..(ffi.arch == "x64" and [[__attribute__((__packed__));]] or [[;]]))
--]=]

ffi.cdef([[
struct epoll_event {
int32_t events;
epoll_data_t data;
}]]..(ffi.arch == "x64" and [[__attribute__((__packed__));]] or [[;]]))



ffi.cdef[[
int epoll_create (int __size) ;
int epoll_create1 (int __flags) ;
int epoll_ctl (int __epfd, int __op, int __fd, struct epoll_event *__event) ;
int epoll_wait (int __epfd, struct epoll_event *__events, int __maxevents, int __timeout);

//int epoll_pwait (int __epfd, struct epoll_event *__events,
//			int __maxevents, int __timeout,
//			const __sigset_t *__ss);
]]

ffi.cdef[[
typedef struct _epollset {
	int epfd;		// epoll file descriptor
} epollset;
]]

local epollset = ffi.typeof("epollset")
local epollset_mt = {
	__new = function(ct, epfd)
		if not epfd then
			epfd = ffi.C.epoll_create1(0);
		end

		if epfd < 0 then
			return nil;
		end

		return ffi.new(ct, epfd)
	end,

	__gc = function(self)
		-- ffi.C.close(self.epfd);
	end;

	__index = {
		add = function(self, fd, event)
			local ret = ffi.C.epoll_ctl(self.epfd, exports.EPOLL_CTL_ADD, fd, event)

			if ret > -1 then
				return ret;
			end

			return false, ffi.errno();
		end,

		delete = function(self, fd, event)
			local ret = ffi.C.epoll_ctl(self.epfd, exports.EPOLL_CTL_DEL, fd, event)

			if ret > -1 then
				return ret;
			end

			return false, ffi.errno();
		end,

		modify = function(self, fd, event)
			local ret = ffi.C.epoll_ctl(self.epfd, exports.EPOLL_CTL_MOD, fd, event)
			if ret > -1 then
				return ret;
			end

			return false, ffi.errno();
		end,

		-- struct epoll_event *__events
		wait = function(self, events, maxevents, timeout)
			maxevents = maxevents or 1
			timeout = timeout or -1

			-- gets either number of ready events
			-- or -1 indicating an error
			local ret = ffi.C.epoll_wait (self.epfd, events, maxevents, timeout);
			if ret == -1 then
				return false, ffi.errno();
			end

			return ret;
		end,
	};
}
ffi.metatype(epollset, epollset_mt);

exports.epollset = epollset;

-- export to global namespace
setmetatable(exports, {
	__call = function(self, params)
		params = params or {}

		if params.exportglobal then
			for k,v in pairs(exports) do
				_G[k] = v;
			end
		end

		return self;
	end;
})

return exports;

