local ffi = require("ffi")
local bit = require("bit")
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift

local exports = require("schedlua.net")


ffi.cdef[[
int close(int fd);
int fcntl (int __fd, int __cmd, ...);
int ioctl (int __fd, unsigned long int __request, ...);

ssize_t read(int fd, void *buf, size_t count);
ssize_t write(int fd, const void *buf, size_t count);
]]

ffi.cdef[[
int inet_aton (__const char *__cp, struct in_addr *__inp);
char *inet_ntoa (struct in_addr __in);
]]

ffi.cdef[[
int socket(int domain, int type, int protocol);
int socketpair(int domain, int type, int protocol, int sv[2]);
ssize_t recv(int sockfd, void *buf, size_t len, int flags);
ssize_t send(int sockfd, const void *buf, size_t len, int flags);
ssize_t sendto(int sockfd, const void *buf, size_t len, int flags, const struct sockaddr *dest_addr, socklen_t addrlen);
ssize_t recvfrom(int sockfd, void *buf, size_t len, int flags, struct sockaddr *src_addr, socklen_t *addrlen);
ssize_t sendmsg(int sockfd, const struct msghdr *msg, int flags);
ssize_t recvmsg(int sockfd, struct msghdr *msg, int flags);
int getsockopt(int sockfd, int level, int optname, void *optval, socklen_t *optlen);
int setsockopt(int sockfd, int level, int optname, const void *optval, socklen_t optlen);
int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
int listen(int sockfd, int backlog);
int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen);
int accept4(int sockfd, void *addr, socklen_t *addrlen, int flags);
int getsockname(int sockfd, struct sockaddr *addr, socklen_t *addrlen);
int getpeername(int sockfd, struct sockaddr *addr, socklen_t *addrlen);
int shutdown(int sockfd, int how);
int sendmmsg(int sockfd, struct mmsghdr *msgvec, unsigned int vlen, unsigned int flags);
int recvmmsg(int sockfd, struct mmsghdr *msgvec, unsigned int vlen, unsigned int flags, struct timespec *timeout);
]]

ffi.cdef[[
struct addrinfo {
  int     ai_flags;          // AI_PASSIVE, AI_CANONNAME, ...
  int     ai_family;         // AF_xxx
  int     ai_socktype;       // SOCK_xxx
  int     ai_protocol;       // 0 (auto) or IPPROTO_TCP, IPPROTO_UDP 

  socklen_t  ai_addrlen;     // length of ai_addr
  struct sockaddr  *ai_addr; // binary address
  char   *ai_canonname;      // canonical name for nodename
  struct addrinfo  *ai_next; // next structure in linked list
};

int getaddrinfo(const char *nodename, const char *servname,
                const struct addrinfo *hints, struct addrinfo **res);

void freeaddrinfo(struct addrinfo *ai);
]]


exports.FIONBIO = 0x5421;


-- Socket level values.
-- To select the IP level.
exports.SOL_IP  = 0;

-- from /usr/include/asm-generic/socket.h
-- For setsockopt(2) 
exports.SOL_SOCKET  = 1;

exports.SO_DEBUG  =1
exports.SO_REUSEADDR  =2
exports.SO_TYPE   =3
exports.SO_ERROR  =4
exports.SO_DONTROUTE  =5
exports.SO_BROADCAST  =6
exports.SO_SNDBUF =7
exports.SO_RCVBUF =8
exports.SO_SNDBUFFORCE  =32
exports.SO_RCVBUFFORCE  =33
exports.SO_KEEPALIVE  =9
exports.SO_OOBINLINE  =10
exports.SO_NO_CHECK =11
exports.SO_PRIORITY =12
exports.SO_LINGER =13
exports.SO_BSDCOMPAT  =14
exports.SO_REUSEPORT  =15
exports.SO_PASSCRED =16
exports.SO_PEERCRED =17
exports.SO_RCVLOWAT =18
exports.SO_SNDLOWAT =19
exports.SO_RCVTIMEO =20
exports.SO_SNDTIMEO =21

exports.SOL_IPV6    = 41;
exports.SOL_ICMPV6  = 58;

exports.SOL_RAW		 = 255;
exports.SOL_DECNET  =    261;
exports.SOL_X25     =    262;
exports.SOL_PACKET  = 263;
exports.SOL_ATM		 = 264;	-- ATM layer (cell level).
exports.SOL_AAL		 = 265;	-- ATM Adaption Layer (packet level).
exports.SOL_IRDA	 = 266;

-- Maximum queue length specifiable by listen.
exports.SOMAXCONN	= 128;


-- for SOL_IP Options
exports.IP_DEFAULT_MULTICAST_TTL     =   1;
exports.IP_DEFAULT_MULTICAST_LOOP    =   1;
exports.IP_MAX_MEMBERSHIPS           =   20;

-- constants should be used for the second parameter of `shutdown'.
exports.SHUT_RD = 0;  -- No more receptions.
exports.SHUT_WR = 1;    -- No more transmissions.
exports.SHUT_RDWR=2;   -- No more receptions or transmissions.


local sockaddr_in = ffi.typeof("struct sockaddr_in");
local sockaddr_in_mt = {
  __new = function(ct, address, port, family)
      family = family or exports.AF_INET;

      local sa = ffi.new(ct)
      sa.sin_family = family;
      sa.sin_port = exports.htons(port)
      if type(address) == "number" then
        addr.sin_addr.s_addr = address;
      elseif type(address) == "string" then
        local inp = ffi.new("struct in_addr")
        local ret = ffi.C.inet_aton (address, inp);
        sa.sin_addr.s_addr = inp.s_addr;
      end

      return sa;
  end;

  __index = {
    setPort = function(self, port)
      self.sin_port = exports.htons(port);
      return self;
    end,
  },

}
ffi.metatype(sockaddr_in, sockaddr_in_mt);
exports.sockaddr_in = sockaddr_in;



-- the filedesc type gives an easy place to hang things
-- related to a file descriptor.  Primarily it keeps the 
-- basic file descriptor.  
-- It also performs the async read/write operations

ffi.cdef[[
typedef struct filedesc_t {
  int fd;
} filedesc;

typedef struct async_ioevent_t {
  struct filedesc_t fdesc;
  int eventKind;
} async_ioevent;
]]


local filedesc = ffi.typeof("struct filedesc_t")
local filedesc_mt = {
    __new = function(ct, fd)
        local obj = ffi.new(ct, fd);

        return obj;
    end;

    __gc = function(self)
        if self.fd > -1 then
            self:close();
        end
    end;

    __index = {
        close = function(self)
            ffi.C.close(self.fd);
            self.fd = -1; -- make it invalid
        end,

        read = function(self, buff, bufflen)
            local bytes = tonumber(ffi.C.read(self.fd, buff, bufflen));

            if bytes > 0 then
                return bytes;
            end

            if bytes == 0 then
              return 0;
            end

            return false, ffi.errno();
        end,

        write = function(self, buff, bufflen)
            local bytes = tonumber(ffi.C.write(self.fd, buff, bufflen));

            if bytes > 0 then
                return bytes;
            end

            if bytes == 0 then
              return 0;
            end

            return false, ffi.errno();
        end,

        setNonBlocking = function(self)
            local feature_on = ffi.new("int[1]",1)
            local ret = ffi.C.ioctl(self.fd, exports.FIONBIO, feature_on)
            return ret == 0;
        end,

    };
}
ffi.metatype(filedesc, filedesc_mt);
exports.filedesc = filedesc;


return exports
